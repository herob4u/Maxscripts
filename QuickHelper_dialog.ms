
Include "rig_commons.ms"

-- @todo: add a pick button to select the parenting bone to all helpers we create?
rollout QuickHelperDialog "Configure Helpers" width:392 height:264
(
	local constraintGroupX = 192
	local constraintGroupY = 48
	
	local offsetGroupX = 192
	local offsetGroupY = 128
	
	local parentGroupX = 192
	local parentGroupY = 172
	
editText baseName_text "Base Name:" pos:[192, 16] width: 160 height:20

groupBox grp1 "Display" pos:[11,8] width:169 height:208
	checkbox centerMarker_checkbox "Center Marker" pos:[32,32] width:88 height:16
	checkbox axisTripod_checkbox "Axis Tripod" pos:[32,56] width:88 height:16
	checkbox cross_checkbox "Cross" pos:[32,80] width:88 height:16
	checkbox box_checkbox "Box" pos:[32,104] width:88 height:16
	spinner size_spinner "Size: " pos:[72,128] width:80 height:16
	checkbox constantScreenSize_checkbox "Constant Screen Size" pos:[32,160] width:136 height:16
	checkbox drawOnTop_checkbox "Draw On Top" pos:[32,184] width:136 height:16

groupBox grp2 "Constraints" pos:[constraintGroupX, constraintGroupY] width:184 height:72
	checkbox rotation_checkbox "Rotation" pos: [16 + constraintGroupX, 24 + constraintGroupY] width:112 height:16
	checkbox position_checkbox "Position" pos: [16 + constraintGroupX, 48 + constraintGroupY] width:112 height:16

groupBox grp3 "Offset" pos:[offsetGroupX,offsetGroupY] width:184 height:48
	spinner xOffset_spinner "X:" pos:[16 + offsetGroupX, 24 + offsetGroupY] width:40 height:16 range:[-1000,1000,0]
	spinner yOffset_spinner "Y:" pos:[72 + offsetGroupX, 24 + offsetGroupY] width:40 height:16 range:[-1000,1000,0]
	spinner zOffset_spinner "Z:" pos:[128 + offsetGroupX, 24 + offsetGroupY] width:40 height:16 range:[-1000,1000,0]
	
groupBox grp4 "Parent" pos:[parentGroupX,parentGroupY] width:184 height:48
	editText parent_text "Parent Name:" pos:[parentGroupX + 16, parentGroupY + 16] width:150 height:24
	
	-- This will be used as spawn parameters for the next helper on the go
	struct HelperInfo
	(
		BaseName = "",
		NameInstance = 0,
		bCenterMarker = false,
		bAxisTripod = false,
		bCross = false,
		bBox = true,
		size = 5,
		bConstantScreenSize = false,
		bDrawOnTop = false,
		Offset = [0,0,0],
		bRotation = true,
		bPosition = false,
		ParentName = ""
	)
	
	-- This is the pending helper information that will be applied after we commit our changes - we do this because constraints are hard to undo/remove
	-- When revisiting this struct, always check for undefined, because the user may have removed the helper before committing
	struct PendingHelperInfo
	(
		HelperObject = undefined,
		BoneObject = undefined,
		ParentObject = undefined,
		bRotation = true,
		bPosition = true
	)
	
	local transientInfo = HelperInfo()
	local pendingHelpers = #()
	
	function initDefaults = 
	(
		centerMarker_checkbox.checked 		= transientInfo.bCenterMarker
		axisTripod_checkbox.checked 			= transientInfo.bAxisTripod
		cross_checkbox.checked 					= transientInfo.bCross
		box_checkbox.checked 					= transientInfo.bBox
		size_spinner.value 							= transientInfo.size
		constantScreenSize_checkbox.checked = transientInfo.bConstantScreenSize
		drawOnTop_checkbox.checked 			= transientInfo.bDrawOnTop
		xOffset_spinner.value 						= transientInfo.Offset.x
		yOffset_spinner.value 						= transientInfo.Offset.y
		zOffset_spinner.value 						= transientInfo.Offset.z
		rotation_checkbox.checked 				= transientInfo.bRotation
		position_checkbox.checked 				= transientInfo.bPosition
	)
	
	function makeHelperName =
	(
		local outName = undefined
		if transientInfo.BaseName != "" then
		(
			outName = transientInfo.BaseName + transientInfo.NameInstance as string
			transientInfo.NameInstance = transientInfo.NameInstance + 1
		)
		
		return outName
	)
	
	function spawnHelper forBone =
	(
		local helper = Point()
		helper.centerMarker = transientInfo.bCenterMarker
		helper.axisTripod = transientInfo.bAxisTripod
		helper.cross = transientInfo.bCross
		helper.box = transientInfo.bBox
		helper.size = transientInfo.size
		helper.constantScreenSize = transientInfo.bConstantScreenSize
		helper.drawOnTop = transientInfo.bDrawOnTop
		
		helper.wirecolor = color 0 255 0
		helper.transform = copy forBone.transform
		helper.objectoffsetpos = transientInfo.Offset
		
		-- Rename the helper if applicable
		local helperName = makeHelperName()
		if helperName != undefined then
		(
			helper.name = helperName
		)
		
		local parentObject = execute ("$'"+transientInfo.ParentName + "'")
		
		-- Add a pending helper
		local pendingHelper = PendingHelperInfo HelperObject:helper BoneObject:forBone ParentObject:parentObject bRotation:transientInfo.bRotation bPosition:transientInfo.bPosition
		append pendingHelpers pendingHelper
		
		return helper
	)
	
	function commit =
	(
		print "committing helpers"
		for pendingHelper in pendingHelpers do
		(
			local helper = pendingHelper.HelperObject
			local bone = pendingHelper.BoneObject
			if helper != undefined and bone != undefined and isValidNode helper and isValidNode bone then
			(
				if pendingHelper.bRotation then
				(
					print "applying rot constraint"
					orientationConstraint bone helper
				)
				
				if pendingHelper.bPosition then
				(
					positionConstraint bone helper
				)
				
				if isValidNode pendingHelper.parentObject then
				(
					linkConstraint helper pendingHelper.parentObject
				)
				
				freezeTransforms helper
			)
		)
		
		pendingHelpers = #()
	)
	
	function abort =
	(
		pendingHelpers = #()
	)
	
	
	on centerMarker_checkbox changed state do ( transientInfo.bCenterMarker = state )
	on axisTripod_checkbox changed state do ( transientInfo.bAxisTripod = state )
	on cross_checkbox changed state do ( transientInfo.bCross = state )
	on box_checkbox changed state do ( transientInfo.bBox = state)
	on constantScreenSize_checkbox changed state do ( transientInfo.bConstantScreenSize )
	on drawOnTop_checkbox changed state do ( transientInfo.bDrawOnTop )
	on size_spinner changed val do ( transientInfo.size = val )
	on rotation_checkbox changed state do ( transientInfo.bRotation = state )
	on position_checkbox changed state do ( transientInfo.bPosition = state )
	on parent_text entered text do ( transientInfo.ParentName = text )
	on xOffset_spinner changed val do ( transientInfo.Offset.x = val )
	on yOffset_spinner changed val do ( transientInfo.Offset.y = val)
	on zOffset_spinner changed val do ( transientInfo.Offset.z = val)
	on baseName_text entered text do
	(
		if text != transientInfo.BaseName then
		(
			transientInfo.BaseName = text
			transientInfo.NameInstance = 0
		)
	)


)