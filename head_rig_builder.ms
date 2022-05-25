fileIn "rig_commons.ms"

-- Head Builder
struct HeadConfig
(
	rigScale = 1,
	
	neck = "",
	head = "",
	
	headOffset = [0, 5, 0]
)
	
struct HeadRigBuilder
(
	transientNodes = #(),
	function isValidConfig headConfig =
	(
		return areBonesConnected headConfig.neck headConfig.head
	),
	
	function makeHelper headConfig forBone =
	(
		if forBone == undefined then
		(
			print "Failed to create helper, invalid bone"
			return undefined
		)
		
		local radius = 5 * headConfig.rigScale
		local thickness = 0.2  * headConfig.rigScale
		local helper = Circle()

		helper.radius = radius
		helper.render_displayRenderMesh = true -- Enable in Viewport
		helper.render_thickness  = thickness
		helper.render_sides = 7
		helper.wirecolor = color 0 0 255

		helper.transform = copy forBone.transform
		helper.objectoffsetrot = EulerAngles 90 0 0
		
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
	
	function buildHead headConfig preview:false = 
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
		
		destroyPreview()
		
		if isValidConfig headConfig then
		(
			print "valid head config"
			local neckBone = execute ("$'"+headConfig.neck + "'")
			local headBone = execute ("$'"+headConfig.head + "'")
			
			local neckHelper = makeHelper headConfig neckBone
			local headHelper  = makeHelper headConfig headBone
			
			neckHelper.name = "HLP_Neck"
			headHelper.name = "HLP_Head"
			
			-- Offset adjust for head halo
			headHelper.objectoffsetpos = headConfig.headOffset
			
			append transientNodes neckHelper
			append transientNodes headHelper
			
			-- Add remaining controllers
			local it = headBone.parent
			local counter = 0
			while it != neckBone do
			(
				local currHelper = makeHelper headConfig it
				currHelper.radius = currHelper.radius * 0.8 -- slightly smaller because USUALLY the neck is smaller than the necks's base
				
				if not isPreview then
				(
					linkConstraint currHelper it.parent
					orientationConstraint it currHelper
					freezeTransforms currHelper
				)
				
				currHelper.name = "HLP_Neck_" + count as string
				
				it = it.parent
				counter = counter +1
				
				append transientNodes currHelper
			)
			
			if not isPreview then
			(
				-- Link 
				linkConstraint neckHelper neckBone.parent
				linkConstraint headHelper headBone.parent
				
				-- Setup Constraints
				orientationConstraint neckBone neckHelper
				orientationConstraint headBone headHelper
				
				-- Freeze!
				freezeTransforms neckHelper
				freezeTransforms headHelper
			)
		)
		else
		(
			print "Invalid head config!"
		)
	)
)

-- headConfig = HeadConfig head:"ValveBiped.Bip01_HeadTop" neck:"ValveBiped.Bip01_Neck1"
-- builder = HeadRigBuilder()
-- builder.buildHead headConfig