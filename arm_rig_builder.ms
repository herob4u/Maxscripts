fileIn "rig_commons.ms"

-- Arm rig builder
struct ArmConfig
(
	rigScale = 1.0,
	
	-- The bone names
	clavicle = "",
	upperArm ="",
	hand = "",
	
	namePrefix = "HLP_L_",
	bTwistControllers = true,	-- Generate twist bones
	twistRotLock = #{BIT_LOCK_ROT_Y, BIT_LOCK_ROT_Z}, -- rotation lock for twist controllers
	clavicleOffset = [3, 3, 0], -- Offset for clavicle controller to pushed out
	elbowSwivelMult = 1,
	
	ikManipTemplate = undefined, -- A template object that will be used as an IK manipulator
	fkRotatorTemplate = undefined -- A template object that will be used as an FK rotator
)

ArmAttributes = attributes "ArmAttributesData"
(
	-- Data structure
	parameters main rollout:armParamsUI
	(
		ElbowSwivel type:#float ui:ElbowSwivel_spinner default:0
-- 		HeelLift type:#float ui:HeelLift_spinner default:0
-- 		ToeTap type:#float ui:ToeTap_spinner default:0
-- 		ToeLift type:#float ui:ToeLift_spinner default:0
-- 		FootTwist type:#float ui:FootTwist_spinner default:0
-- 		KneeSwivel type:#float ui:KneeSwivel_spinner default:0
	)
	
	-- UI driver for data
	rollout armParamsUI "Arm Parameters"
	(
		spinner ElbowSwivel_spinner "Elbow Swivel" type: #float range:[-10,10, 0]
	)
)

struct ArmRigBuilder
(
	-- Cached
	traversalNodes = #(),
	transientNodes = #(), -- For preview
	
	function isValidConfig armConfig =
	(
		if traversalNodes == undefined then
		(
			print "traversal nodes list is undefined!"
			return false
		)
		
		local clavicleBone = execute ("$'"+armConfig.clavicle + "'")
		if clavicleBone == undefined then return false
			
		local success = getTraversalPath armConfig.clavicle armConfig.hand &traversalNodes
		format "traversal nodes count % \n traversalNodes: % \n" traversalNodes.count traversalNodes
		return success
	),

	function makeIKManipulator armConfig forBone =
	(
		-- @todo: maybe should instance instead
		local manipulator = copy armConfig.ikManipTemplate
		if manipulator == undefined then
		(
			-- Create a place holder one
			local radius = 2 * armConfig.rigScale
			manipulator = Circle()
			manipulator.radius = radius
			manipulator.wirecolor = color 255 0 0
			manipulator.render_displayRenderMesh  = true
			manipulator.render_thickness = 0.1 * armConfig.rigScale
			manipulator.render_sides = 6
			
			manipulator.transform = copy forBone.transform
			manipulator.objectoffsetrot = EulerAngles 90 0 0
		)
		else
		(
			-- If a template, just align and adjust its scale according to rig scale
			manipulator.transform = copy forBone.transform
			manipulator.scale = [armConfig.rigScale, armConfig.rigScale, armConfig.rigScale]
		)
		
		return manipulator
	),

	function makeFKRotator armConfig forBone =
	(
		-- @todo: maybe should instance instead
		local rotator = copy armConfig.fkRotatorTemplate
		if rotator == undefined then
		(
			-- create a placeholder one
			local radius = 1 * armConfig.rigScale
			rotator = Circle()
			rotator.radius = radius
			rotator.wirecolor = color 0 0 255
			rotator.render_displayRenderMesh = true
			rotator.render_thickness = 0.15 * armConfig.rigScale
			rotator.render_sides = 6
			
			rotator.transform = copy forBone.transform
		)
		
		return rotator
	),

	function makeTwistRotator armConfig forBone =
	(
		-- create a placeholder one
		local radius = 2 * armConfig.rigScale
		local rotator = Circle()
		rotator.radius = radius
		rotator.wirecolor = color 0 255 0
		rotator.render_displayRenderMesh = true
		rotator.render_thickness = 0.15 * armConfig.rigScale
		rotator.render_sides = 6
		
		rotator.transform = copy forBone.transform
		rotator.objectoffsetrot = EulerAngles 0 90 0
		
		return rotator
	),

	function setupHandAttributes armConfig handManip handIk =
	(
		-- Add the custom attributes
		local attribHolder =  EmptyModifier()
		addModifier handManip attribHolder
		
		custAttributes.add attribHolder ArmAttributes
		
		-- Wire the elbow swivel
		local ss = stringstream ""
		format "degToRad(ElbowSwivel * 10 * %)" armConfig.elbowSwivelMult to:ss
		paramWire.connect attribHolder.ArmAttributesData[#ElbowSwivel] handIk.transform.controller[#Swivel_Angle] ss as string
	),
	
	function destroyPreview = 
	(
		for node in transientNodes do
		(
			delete node
		)
		
		transientNodes = #()
	),
	
	function buildArm armConfig preview:false =
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
		
		-- Destroy any previous previews for rebuild
		destroyPreview()
		
		traversalNodes = #()
		if isValidConfig armConfig then
		(
			print "Valid arm configs"
			local clavicleBone = execute ("$'"+armConfig.clavicle + "'")
			local upperArmBone  = execute ("$'"+armConfig.upperArm + "'")
			local handBone   = execute ("$'"+armConfig.hand + "'")
			
			-- Create the clavicle rotation controller
			local clavicleRotator = makeFKRotator armConfig clavicleBone
			clavicleRotator.name = armConfig.namePrefix + "Clavicle"
			clavicleRotator.objectoffsetpos = armConfig.clavicleOffset
			
			-- Create hand IK manipulator 
			local handManip = makeIKManipulator armConfig handBone
			handManip.name = armConfig.namePrefix + "Hand"
			
			local handIk
			if not isPreview then
			(
				-- Create IK between upper arm and hand
				handIk = makeIk upperArmBone handBone
				setupHandAttributes armConfig handManip handIk
			)
			else
			(
				append transientNodes handManip
				append transientNodes clavicleRotator
			)
			
			-- Iterate down to hand to find any arm bones that need twist controllers
			-- Iterating down to 2 because want to exclude hand bone (traversal is returned in reverse)
			for i = traversalNodes.count to 2 by -1 do
			(
				--format "searching traversal nodes: %\n\n" i
				
				-- For each bone in our traversal, check its children. There are 3 cases:
				-- 1) The child bone is the next bone in the traversal path - hence cannot be a twist bone
				-- 2) The child bone is one of our root bones, hence cannot be a twist bone
				-- 3) Else, must be a twist bone, or some other attachment bone
				--local rootBone = execute ("$'"+traversalNodes[i] + "'")
				local rootBone = traversalNodes[i]
				if rootBone == undefined then continue
					
				for child in rootBone.children do
				(
					-- Not one of the root bones, candidate for twist bone
					if(child != clavicleBone and child != upperArmBone and child != handBone) then
					(
						--format "candidate twist bone: %\n" child.name
						-- Not in the traversal path either, must be a twist/attachment bone
						if findItem traversalNodes child == 0 then
						(
							local rotator = makeTwistRotator armConfig child
							rotator.name = armConfig.namePrefix + "ArmTwist_" + i as string
							
							-- Preview mode does not do any constraining!
							if not isPreview then
							(
								linkConstraint rotator rootBone
								orientationConstraint child rotator
								freezeTransforms rotator
								
								setTransformLockFlags rotator armConfig.twistRotLock
							)
							else
							(
								append transientNodes rotator
							)
						)
					)
				)
			)
			
			-- Parent then freeze
			if not isPreview then
			(
				linkConstraint clavicleRotator clavicleBone.parent
				orientationConstraint handBone handManip
				orientationConstraint clavicleBone clavicleRotator
				
				handIk.parent = handManip
				
				freezeTransforms handManip
				freezeTransforms clavicleRotator
			)
		)
		else
		(
			print "Invalid arm configs"
		)
	)
)
-- armConfig = ArmConfig 1 clavicle:"ValveBiped.Bip01_L_Clavicle" upperArm:"ValveBiped.Bip01_L_UpperArm" hand:"ValveBiped.Bip01_L_Hand"
-- buildArm armConfig