fileIn "rig_commons.ms"

rollout RigJointDialog "Configure Helpers" width:392 height:320
(
		-- function declarations
	local recreateHelpers, refreshHelperDisplay, applyConstraints, destroyHelpers
	
	local LINK_MODE_PARENT_BONE = 1
	local LINK_MODE_PARENT_HELPER = 2
	local LINK_MODE_OUTER_HELPER = 3
	local LINK_MODE_NONE = 4
	
	struct HelperDisplayInfo
	(
		bCenterMarker = false,
		bAxisTripod = false,
		bCross = false,
		bBox = true,
		size = 5,
		bConstantScreenSize = false,
		bDrawOnTop = false,
		Offset = [0, 0, 0]
	)
	
	struct HelperConstraintInfo
	(
		bRotation = true,
		bPosition = false,
		bIkJoint = false,
		linkMode = LINK_MODE_PARENT_BONE
	)
	
	local displayInfo = HelperDisplayInfo()
	local constraintInfo = HelperConstraintInfo()
	local selectedJoints = #()
	local primaryHelpers = #()
	local secondaryHelpers = #()
	local bAccepted = false
	local baseName = "HLP_"
	
	groupBox grp1 "Display" pos:[11,8] width:169 height:208
		checkbox centerMarker_checkbox "Center Marker" pos:[32,32] width:88 height:16
		checkbox axisTripod_checkbox "Axis Tripod" pos:[32,56] width:88 height:16
		checkbox cross_checkbox "Cross" pos:[32,80] width:88 height:16
		checkbox box_checkbox "Box" pos:[32,104] width:88 height:16
		spinner size_spinner "Size: " pos:[72,128] width:80 height:16
		checkbox constantScreenSize_checkbox "Constant Screen Size" pos:[32,160] width:136 height:16
		checkbox drawOnTop_checkbox "Draw On Top" pos:[32,184] width:136 height:16
	
	groupBox grp2 "Constraints" pos:[192,8] width:184 height:152
		checkbox rotation_checkbox "Rotation" pos:[208,32] width:112 height:16
		checkbox position_checkbox "Position" pos:[208,56] width:112 height:16
		checkbox ik_checkbox "IK Joints" pos:[208,80] width:112 height:16
		dropDownList linkMode_dropdown "Link Mode" pos:[208,112] width:144 height:40 items:#("Link to parent bone", "Link to parent helper", "Link to outer helper", "No link")
	
	groupBox grp3 "Offset" pos:[192,168] width:184 height:48
		spinner xOffset_spinner "X:" pos:[208,192] width:40 height:16 range:[-1000,1000,0]
		spinner yOffset_spinner "Y:" pos:[264,192] width:40 height:16 range:[-1000,1000,0]
		spinner zOffset_spinner "Z:" pos:[320,192] width:40 height:16 range:[-1000,1000,0]
		
	
	button accept_button "Accept" pos:[131, 255] width:130 height:40
	editText baseName_text "Base Name:" pos:[16, 225] width: 160 height:20
	
	function initDefaults =
	(
		centerMarker_checkbox.checked = displayInfo.bCenterMarker
		axisTripod_checkbox.checked = displayInfo.bAxisTripod
		cross_checkbox.checked = displayInfo.bCross
		box_checkbox.checked = displayInfo.bBox
		size_spinner.value = displayInfo.size
		constantScreenSize_checkbox.checked = displayInfo.bConstantScreenSize
		drawOnTop_checkbox.checked = displayInfo.bDrawOnTop
		
		rotation_checkbox.checked = constraintInfo.bRotation
		position_checkbox.checked = constraintInfo.bPosition
		ik_checkbox.checked = constraintInfo.bIkJoint
		linkMode_dropdown.selection = constraintInfo.linkMode
		
		xOffset_spinner.value = displayInfo.Offset.x
		yOffset_spinner.value = displayInfo.Offset.y
		zOffset_spinner.value = displayInfo.Offset.z

		baseName_text.text = baseName
	)
	
	on RigJointDialog close do
	(
		if bAccepted == false then
		(
			destroyHelpers()
		)
	)
	
	function destroyHelpers = 
	(
		for helper in primaryHelpers do
		(
			delete helper
		)
		primaryHelpers = #()
		
		for helper in secondaryHelpers do
		(
			delete helper
		)
		secondaryHelpers = #()
	)
	
	function recreateHelpers =
	(
		destroyHelpers()
		
		local bCreateOuterHelpers = (constraintInfo.linkMode == LINK_MODE_OUTER_HELPER)
		for joint in selectedJoints do
		(
			local helper = Point()
			helper.transform = copy joint.transform
			helper.wirecolor = color 0 255 0
			
			-- Add to array
			append primaryHelpers helper
			
			if bCreateOuterHelpers then
			(
				local outerHelper = Point()
				outerHelper.transform = copy joint.transform
				outerHelper.cross = false
				outerHelper.box = true
				outerHelper.wirecolor = color 255 0 0
				
				append secondaryHelpers outerHelper
			)
		)
		
		refreshHelperDisplay()
	)
	
	function refreshHelperDisplay =
	(
		-- We may switch the link mode, at which point we need to update the secondary helpers
		local bCreateOuterHelpers = (constraintInfo.linkMode == LINK_MODE_OUTER_HELPER)
		if (bCreateOuterHelpers and secondaryHelpers.count == 0) or (not bCreateOuterHelpers and secondaryHelpers.count > 0) then
		(
			recreateHelpers()
		)
		
		for i = 1 to primaryHelpers.count do
		(
			local helper = primaryHelpers[i]
			if helper == undefined then throw "Expected valid helper!"

			-- Do the primary helpers first
			helper.centermarker = displayInfo.bCenterMarker
			helper.axisTripod = displayInfo.bAxisTripod
			helper.cross = displayInfo.bCross
			helper.box = displayInfo.bBox
			helper.size = displayInfo.size
			helper.drawOnTop = displayInfo.bDrawOnTop
			helper.constantScreenSize = displayInfo.bConstantScreenSize
			
			helper.objectoffsetpos = displayInfo.Offset
			
			-- Update outer helpers second since they are dependent on inner ones
			if secondaryHelpers.count > 0 then
			(
				local outerHelper = secondaryHelpers[i]
				local outerHelperSize = helper.size * 1.25
				if outerHelper == undefined then throw "Expected valid helper!"
					
				outerHelper.size = outerHelperSize
				outerHelper.objectoffsetpos = displayInfo.Offset
			)
		)
	)
	
	function applyConstraints =
	(
		if primaryHelpers.count == 0 then
		(
			print "Failed to apply constraints, helpers were not ready!"
			return undefined
		)
		
		for i = 1 to selectedJoints.count do
		(
			local helper = primaryHelpers[i]
			local joint = selectedJoints[i]
			
			if helper == undefined or joint == undefined then throw "Expected valid helpers and joints by now!"
			
			-- Naming happens now
			helper.name = baseName + i as string
			
			if constraintInfo.bRotation then
			(
				orientationConstraint joint helper
			)
			
			if constraintInfo.bPosition then
			(
				positionConstraint joint helper
			)
			
			if constraintInfo.bIkJoint then
			(
				if i > 1 then
				(
					local prevJoint = joint.parent
					if prevJoint != undefined then
					(
						local ikEffector = makeIk prevJoint joint
						ikEffector.parent = helper
					)
				)
			)
			
			-- Linking time ...
			local linkMode = constraintInfo.linkMode
			if linkMode == LINK_MODE_PARENT_BONE then
			(
				-- Get the parent of the joint we are controlling and link to it
				local parentJoint = joint.parent
				if parentJoint != undefined then -- could possibly be at start of heirarchy, no parent
				(
					linkConstraint helper parentJoint
				)
			)
			else if linkMode == LINK_MODE_PARENT_HELPER then
			(
				if i > 1 then
				(
					-- Get the previous helper in the hierarchy and link to it
					local parentHelper = primaryHelpers[i-1]
					if parentHelper != undefined then
					(
						parentHelper.name = baseName + i as string + "_Outer"
						helper.parent = parentHelper
					)
				)
			)
			else if linkMode == LINK_MODE_OUTER_HELPER then
			(
				local outerHelper = secondaryHelpers[i]
				if outerHelper != undefined then -- could get here by UI error?
				(
					helper.parent = outerHelper
				)
			)
		)
	)
	
	on centerMarker_checkbox changed state do
	(
		displayInfo.bCenterMarker = state
		refreshHelperDisplay()
	)
	on axisTripod_checkbox changed state do
	(
		displayInfo.bAxisTripod = state
		refreshHelperDisplay()
	)
	on cross_checkbox changed state do
	(
		displayInfo.bCross = state
		refreshHelperDisplay()
	)
	on box_checkbox changed state do
	(
		displayInfo.bBox = state
		refreshHelperDisplay()
	)
	on size_spinner changed val do
	(
		displayInfo.size = val
		refreshHelperDisplay()
	)
	on constantScreenSize_checkbox changed state do
	(
		displayInfo.bConstantScreenSize = state
		refreshHelperDisplay()
	)
	on drawOnTop_checkbox changed state do
	(
		displayInfo.bDrawOnTop = state
		refreshHelperDisplay()
	)
	on rotation_checkbox changed state do
	(
		constraintInfo.bRotation = state
	)
	on position_checkbox changed state do
	(
		constraintInfo.bPosition = state
	)
	
	-- IK is a special case, if the joints are IKed, then we can't apply an orientation or position constraint. Nor can we link to the bones.
	on ik_checkbox changed state do
	(
		constraintInfo.bIkJoint = state
		if state == true then
		(
			if linkMode_dropdown.selection == LINK_MODE_PARENT_BONE then
			(
				linkMode_dropdown.selection = LINK_MODE_NONE
			)
			
			if rotation_checkbox.enabled or position_checkbox.enabled then
			(
				rotation_checkbox.checked = false
				position_checkbox.checked = false
				rotation_checkbox.enabled = false
				position_checkbox.enabled = false
			)
			
			-- Update the info
			constraintInfo.linkMode = linkMode_dropdown.selection
			constraintInfo.bRotation = rotation_checkbox.checked
			constraintInfo.bPosition = position_checkbox.checked
		)
		else
		(
			if not rotation_checkbox.enabled or not position_checkbox.enabled then
			(
				rotation_checkbox.enabled = true
				position_checkbox.enabled = true
			)
		)
	)
	
	-- IK is a special case, if it is enabled, then prevent selection of linking to bone
	on linkMode_dropdown selected sel do
	(
		if constraintInfo.bIkJoint then
		(
			if sel == LINK_MODE_PARENT_BONE then
			(
				linkMode_dropdown.selection = constraintInfo.linkMode -- whatever was previous
				messagebox "Cannot link helpers to bones in an IK setup"
				return undefined
			)
		)
		
		local bNeedsRefresh = (sel == LINK_MODE_OUTER_HELPER or constraintInfo.linkMode == LINK_MODE_OUTER_HELPER)
		constraintInfo.linkMode = sel
		
		if(bNeedsRefresh) then refreshHelperDisplay()
	)
	on xOffset_spinner changed val do
	(
		displayInfo.Offset.x = val
		refreshHelperDisplay()
	)
	on yOffset_spinner changed val do
	(
		displayInfo.Offset.y = val
		refreshHelperDisplay()
	)
	on zOffset_spinner changed val do
	(
		displayInfo.Offset.y = val
		refreshHelperDisplay()
	)
	
	on baseName_text entered text do
	(
		baseName = text
	)
	
	on accept_button pressed do
	(
		bAccepted = true
		applyConstraints()
		destroyDialog RigJointDialog
	)
)

--createDialog RigJointDialog