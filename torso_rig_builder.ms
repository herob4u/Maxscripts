
fileIn "rig_commons.ms"

struct TorsoConfig
(
	rigScale = 1,
	spineBegin = " ",
	spineEnd   = " ",
	boneSearchName = "spine"
)

struct TorsoRigBuilder
(
	transientNodes = #(),
	
	-- Find the next possible spine bone in the hierarchy - this does not guarantee the bone is a spine bone, but if it isn't, then nothing else is.
	function findNextSpineBone forBone torsoConfig=
	(
		if forBone == undefined or forBone.children == undefined then return undefined
			
		-- Trivial case, one child bone (usual case), just return the child
		if(forBone.children.count == 1) then return forBone.children[1]
		
		print "Entering non-trivial case"

		local patternStr = "*"+torsoConfig.boneSearchName+"*"
		for child in forBone.children do
		(
			if matchPattern child.name pattern:patternStr ignoreCase:true then
			(
				return child
			)
		)
		
		return forBone.children[1]
	),

	-- Checks whether the two spine bones are actually connected
	function isValidConfig torsoConfig =
	(
		if torsoBegin == "" or torsoEnd == "" then return false
		
		print torsoConfig.spineBegin
		print torsoConfig.spineEnd
		
		local spineBeginBone = execute ("$'"+torsoConfig.spineBegin + "'")
		local spineEndBone  = execute ("$'"+torsoConfig.spineEnd + "'")
		
		if spineBeginBone == undefined or spineEndBone == undefined then return false
		else print "spine bones valid"
		
		local it = spineBeginBone
		while it != undefined do
		(
			if(it == spineEndBone) then return true
			
			if(it.children == undefined) then return false
			
			it = findNextSpineBone it torsoConfig -- Assume first child is always the next spine bone
		)
		
		return false
	),

	-- Creates the spline controller for the spine, and assigns the constraints
	function makeHelper forBone rigScale =
	(
		if forBone == undefined then
		(
			print "Failed to create helper, invalid bone"
			return false
		)
		
		print "Make helper called"
		local radius = 8 * rigScale
		local thickness = 0.2  * rigScale
		local helper = Circle()
		
		helper.radius = radius
		helper.render_displayRenderMesh = true -- Enable in Viewport
		helper.render_thickness  = thickness
		helper.render_sides = 7
		helper.wirecolor = color 0 0 255
		
		helper.transform = copy forBone.transform
		helper.objectoffsetrot = EulerAngles 90 0 0
		
		-- Perform linking
		--linkConstraint helper forBone.parent
		
		-- Perform constraints
		--orientationConstraint forBone helper
		
		return helper
	),

	function destroyPreview =
	(
		for node in transientNodes do
		(
			delete node
		)
		
		transientNodes = #()
	),
	
	function buildTorso torsoConfig preview:false =
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
		
		if torsoConfig == undefined then print "UNDEFINED TORSO CONFIG!!!"
		
		destroyPreview()
		
		local isValid = isValidConfig torsoConfig
		
		if isValid then
		(
			print "Valid torso configuration"
			local spineBeginBone = execute ("$'"+torsoConfig.spineBegin + "'")
			local spineEndBone  = execute ("$'"+torsoConfig.spineEnd + "'")
			
			local it = spineBeginBone
			local idx = 0
			do
			(
				format "building torso rig for bone %... it = %\n" it.name idx
				local helper = makeHelper it torsoConfig.rigScale
				helper.name = "HLP_Spine_" + idx as string
				
				append transientNodes helper
				if not isPreview then
				(
					-- Perform linking
					linkConstraint helper it.parent
					
					-- Perform constraints
					orientationConstraint it helper
				)
				
				it = findNextSpineBone it torsoConfig
				idx = idx+1
			)
			while it != undefined and it.parent != spineEndBone
		)
		else
		(
			print "Invalid torso configuration!"
		)
	)
)
-- torsoConfig = TorsoConfig 1 "ValveBiped.Bip01_Spine" "ValveBiped.Bip01_Spine4"
-- torsoBuilder = TorsoRigBuilder()
-- torsoBuilder.buildTorso torsoConfig