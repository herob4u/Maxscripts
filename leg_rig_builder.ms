fileIn "rig_commons.ms"

-- Leg Rig Builder
struct LegConfig
(
	rigScale = 1,
	thigh = " ",
	foot  = " ",
	toe  = " ",
	toeNub = " ",
	namePrefix = "HLP_",

	-- Custom Attributes
	bKneeSwivel = true,
	bHeelPeel = true,
	bHeelLift = true,
	bToeLift = true,
	bToeTap = true,
	bFootTwist = true,
	bUseIKGoal = true, -- for knee swivels
	
	kneeSwivelMult = 1,
	heelPeelMult = 1,
	heelLiftMult = 1,
	toeLiftMult = 1,
	toeTapMult = 1,
	footTwistMult = 1,
	
	-- User provided master controller
	legMasterController = undefined,
	legMasterOffset = [0, -2, 3]
)

LegAttributes = attributes "LegAttributeData"
(
	-- Data structure
	parameters main rollout:legParamsUI
	(
		HeelPeel type:#float ui:HeelPeel_spinner default:0
		HeelLift type:#float ui:HeelLift_spinner default:0
		ToeTap type:#float ui:ToeTap_spinner default:0
		ToeLift type:#float ui:ToeLift_spinner default:0
		FootTwist type:#float ui:FootTwist_spinner default:0
		KneeSwivel type:#float ui:KneeSwivel_spinner default:0
	)
	
	-- UI driver for data
	rollout legParamsUI "Leg Parameters"
	(
		spinner HeelPeel_spinner "Heel Peel" type: #float range:[-10,10, 0]
		spinner HeelLift_spinner "Heel Lift" type: #float range:[0, 10, 0]
		spinner ToeTap_spinner "Toe Tap" type: #float range:[-10, 10, 0]
		spinner ToeLift_spinner "Toe Lift" type: #float range:[0, 10, 0]
		spinner FootTwist_spinner "Foot Twist" type: #float range:[-10,10,0]
		spinner KneeSwivel_spinner "Knee Swivel" type: #float range:[-10,10,0]
	)
)

-------------------- Leg Rig Builder --------------------------
struct LegRigBuilder
(
	transientNodes = #(),
	function isValidConfig legConfig =
	(
		if not areBonesConnected legConfig.thigh legConfig.foot then
		(
			print "Thigh not connected to foot"
			return false
		)
		if not areBonesConnected legConfig.foot legConfig.toe then
		(
			print "foot not connected to toe"
			return false

		)
		if not areBonesConnected legConfig.toe legConfig.toeNub then
		(
			print "toe not connected to toe nub"
			return false
		)
		
		print "all bones fully connected"
		return true
	),

	function makeHelper forBone legConfig sizeMultiplier =
	(
		if forBone == undefined then
		(
			print "Failed to create helper for leg - invalid bone"
		)
		
		local helper = Point()
		helper.cross = false
		helper.box = true
		helper.size = 2 * sizeMultiplier * legConfig.rigScale
		helper.wirecolor = color 0 255 0
		
		-- Align pivot to pivot
		helper.transform = copy forBone.transform
		
		return helper
	),

	function makeFootMaster legConfig heelHelper twistHelper=
	(
		local masterController = legConfig.legMasterController
		if(masterController == undefined) then
		(
			-- Build it ourself using the extent formed by the helpers
			local width = 3 * legConfig.rigScale
			local length = (distance heelHelper.position twistHelper.position) * 1.5 -- buffer 25%
			
			masterController = Rectangle()
			masterController.width = width
			masterController.length = length
			
			masterController.transform = copy heelHelper.transform
			masterController.objectoffsetrot = EulerAngles 90 0 0
			
			masterController.objectoffsetpos = legConfig.legMasterOffset
			
			-- Visuals
			masterController.wirecolor = color 255 0 0
			masterController.render_displayRenderMesh  = true
			masterController.render_thickness = 0.1 * legConfig.rigScale
			masterController.render_sides = 6
		)
		
		return masterController
	),

	function setupLegAttributes legConfig masterController heelHelper toeHelper toeTapHelper twistHelper footIk =
	(	
		-- Add the custom attributes
		local attribHolder =  EmptyModifier() -- an empty object?
		addModifier masterController attribHolder
		
		custAttributes.add attribHolder LegAttributes
		print heelHelper.rotation.controller
		
		if (legConfig.bHeelPeel) then
		(
			local ss = stringstream ""
			format "degToRad(HeelPeel * -10 * %)" legConfig.heelPeelMult to:ss
			--local expr = "degToRad(HeelPeel * -10)" -- evaluated from (100 -(-100))/ (10 - (-10))
			paramWire.connect attribHolder.LegAttributeData[#HeelPeel] heelHelper.rotation.controller.Zero_Euler_XYZ.controller[#X_Rotation] ss as string
		)
		
		if legConfig.bHeelLift then
		(
			local ss = stringstream ""
			--local expr = "degToRad(HeelLift * 10)" -- evaluated from (100 -(-100))/ (10 - (-10))
			format "degToRad(HeelLift * 10 * %)" legConfig.heelLiftMult to:ss
			paramWire.connect attribHolder.LegAttributeData[#HeelLift] toeHelper.rotation.controller.Zero_Euler_XYZ.controller[#X_Rotation] ss as string
		)
		
		if legConfig.bToeLift then
		(
			local ss = stringstream ""
			--local expr = "degToRad(ToeLift * 10)" -- evaluated from (100 -(-100))/ (10 - (-10))
			format "degToRad(ToeLift * 10 * %)" legConfig.toeLiftMult to:ss 
			paramWire.connect attribHolder.LegAttributeData[#ToeLift] twistHelper.rotation.controller.Zero_Euler_XYZ.controller[#X_Rotation] ss as string
		)
		
		if legConfig.bToeTap then
		(
			local ss = stringstream ""
			--local expr = "degToRad(ToeTap * -10)" -- evaluated from (100 -(-100))/ (10 - (-10))
			format "degToRad(ToeTap * -10 * %)" legConfig.toeTapMult to:ss 
			paramWire.connect attribHolder.LegAttributeData[#ToeTap] toeTapHelper.rotation.controller.Zero_Euler_XYZ.controller[#X_Rotation] ss as string
		)
		
		if legConfig.bFootTwist then
		(
			local ss = stringstream ""
			--local expr = "degToRad(FootTwist * -10)" -- evaluated from (100 -(-100))/ (10 - (-10))
			format "degToRad(FootTwist * -10 * %)" legConfig.footTwistMult to:ss 
			paramWire.connect attribHolder.LegAttributeData[#FootTwist] twistHelper.rotation.controller.Zero_Euler_XYZ.controller[#Y_Rotation] ss as string
		)
		
		if legConfig.bUseIKGoal then
		(
		)
		
		if(legConfig.bKneeSwivel) then
		(
			local ss = stringstream ""
			format "degToRad(KneeSwivel * 12 * %)" legConfig.kneeSwivelMult to:ss 
			--local expr = "degToRad(KneeSwivel * 12)"
			paramWire.connect attribHolder.LegAttributeData[#KneeSwivel] footIk.transform.controller[#Swivel_Angle] ss as string
		)
	),

	function destroyPreview =
	(
		for node in transientNodes do
		(
			delete node
		)
		
		transientNodes = #()
	),
	
	function buildLeg legConfig preview:false = 
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
		
		destroyPreview()
		
		local isValid = isValidConfig legConfig
		if(isValid) then
		(
			print "Valid leg config"
			local thighBone = execute ("$'"+legConfig.thigh + "'")
			local footBone  = execute ("$'"+legConfig.foot + "'")
			local toeBone   = execute ("$'"+legConfig.toe + "'")
			local toeNubBone  = execute ("$'"+legConfig.toeNub + "'")

			local footIk
			local toeIk
			local toeNub
			if not isPreview then
			(
				footIk = makeIk thighBone footBone
				toeIk = makeIk footBone toeBone
				toeNubIk = makeIk toeBone toeNubBone
			)
			
			local heelHelper = makeHelper footBone legConfig 1
			local toeHelper = makeHelper toeBone legConfig 0.8
			local toeTapHelper = makeHelper toeBone legConfig 1
			local twistHelper = makeHelper toeNubBone legConfig 0.5
			local masterController = makeFootMaster legConfig heelHelper twistHelper
			
			-- Naming!
			heelHelper.name 			= legConfig.namePrefix + "Heel"
			toeHelper.name			= legConfig.namePrefix + "Toe"
			toeTapHelper.name 		= legConfig.namePrefix + "ToeTap"
			twistHelper.name			= legConfig.namePrefix + "FootTwist"
			masterController.name 	= legConfig.namePrefix + "FootMaster"
			
			if not isPreview then
			(
				-- Link the IK nodes
				footIk.parent = toeHelper
				toeIk.parent = toeHelper
				toeNubIk.parent = toeTapHelper
				
				-- Link the helpers
				twistHelper.parent = heelHelper
				toeHelper.parent = twistHelper
				toeTapHelper.parent = twistHelper
				heelHelper.parent = masterController
				
				-- Freeze transforms after parenting
				freezeTransforms heelHelper
				freezeTransforms toeHelper
				freezeTransforms toeTapHelper
				freezeTransforms twistHelper
				freezeTransforms masterController
				
				-- Create the master controller
				setupLegAttributes legConfig masterController heelHelper toeHelper toeTapHelper twistHelper footIk
			)
			else
			(
				append transientNodes heelHelper
				append transientNodes toeHelper
				append transientNodes toeTapHelper
				append transientNodes twistHelper
				append transientNodes masterController
			)
		)
		else
		(
			print "Invalid leg config!"
		)
	)
)

-- legConfig = legConfig 1 "ValveBiped.Bip01_L_Thigh" "ValveBiped.Bip01_L_Foot" "ValveBiped.Bip01_L_Toe0" "lToe"
-- builder = LegRigBuilder()
-- builder.buildLeg legConfig