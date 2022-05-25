rollout limbHelperGenerator "Untitled" width:496 height:552
(
	pickButton pickRoot_button "Pick Root Bone" pos:[24,16] width:246 height:56
	label boneName_label "Root Bone:" pos:[24,80] width:248 height:32
	groupBox grp1 "Helper Settings" pos:[16,128] width:248 height:336
	spinner zOffset_spinner "Z-Offset     " pos:[32,160] width:224 height:16 range:[0,100,0]
	spinner helperSize_spinner "Helper Size" pos:[32,184] width:224 height:16 range:[0.01,100,0]
	button generate_button "Generate" pos:[144,480] width:205 height:49
	spinner maxDepth_spinner "Max Depth" pos:[32,208] width:224 height:16 range:[0,100,0] type:#integer
	editText namePrefix_textfield "Name Prefix" pos:[24,232] width:224 height:24
	dropDownList linkMode_dropDown "Link Mode" pos:[24,264] width:232 height:40 items:#("Link to root bone", "Link to parent bone", "Link to parent helper", "No linking")
	groupBox grp2 "Bone Constraints" pos:[32,368] width:216 height:80
	checkbox posConstraint_checkbox "Position" pos:[48,384] width:72 height:16
	checkbox rotConstraint_checkbox "Rotation" pos:[48,400] width:72 height:16
	checkbox linkConstraint_checkbox "Link" pos:[48,416] width:72 height:16
	dropDownList dropDown_sizingMode "Sizing Mode" pos:[24,312] width:128 height:40 items:#("Fixed Size", "Scale Children", "Fixed Children Scale", "Fixed Children Size")
	spinner sizeValue_spinner "Value" pos:[168,336] width:88 height:16 enabled:false range:[0.01,100,0] scale:0.1
	groupBox grp15 "Include/Exclude" pos:[280,128] width:200 height:336
	listBox inclusion_list "ListBox" pos:[288,200] width:184 height:11
	dropDownList inclusionMode_dropDown "Mode" pos:[288,152] width:176 height:40 items:#("Include", "Exclude")
	pickButton listAdd_button "Add" pos:[288,376] width:88 height:32
	button listRemove_button "Remove" pos:[383,375] width:86 height:33
	
	local SIZE_MODE_FIXED_SIZE = 1
	local SIZE_MODE_SCALE_CHILDREN = 2
	local SIZE_MODE_FIXED_SCALE_CHILDREN = 3
	local SIZE_MODE_FIXED_SIZE_CHILDREN = 4
	
	local LINK_MODE_ROOT_BONE = 1
	local LINK_MODE_PARENT_BONE = 2
	local LINK_MODE_PARENT_HELPER = 3
	local LINK_MODE_NONE = 4
	
	local INCLUDE_MODE = 1
	local EXCLUDE_MODE = 2
	
	struct HelperSettings
	(
		rootBone = undefined,
		zOffset = 0,
		helperSize = 1,
		maxDepth = 100,
		namePrefix = "HLP_"
	)

	struct ConstraintSettings
	(
		linkMode = LINK_MODE_PARENT_HELPER,
		bPosition = false,
		bRotation = false,
		bLink = false
	)

	struct SizingSettings
	(
		sizingMode = SIZE_MODE_FIXED_SIZE,
		sizingValue = 1
	)

	struct InclusionSettings
	(
		inclusionMode = EXCLUDE_MODE
	)
	
	local g_helperSettings = HelperSettings()
	local g_constraintSettings = ConstraintSettings()
	local g_sizingSettings = SizingSettings()
	local g_inclusionSettings = InclusionSettings()
	
	local g_previewHelpers = #()
	
	-- Function declarations
	local createHelperRecursive, needsRotationConstraint, needsPositionConstraint, needsLinkConstraint, makeHelperName, applyRotationConstraint, applyPositionConstraint, 
	applyLinkConstraint, applyLinkAttachment, initDefaults, isValidBone, getHelperSize, isBoneType, rebuildPreview, destroyPreview
	
	-- Default constructor - convenience for syncing UI
	function initDefaults =
	(
		print "Initializing Default Values"
		
		-- Helper Settings
		zOffset_spinner.value = g_helperSettings.zOffset
		maxDepth_spinner.value = g_helperSettings.maxDepth
		helperSize_spinner.value = g_helperSettings.helperSize
		namePrefix_textfield.text = g_helperSettings.namePrefix
		
		-- Constraint Settings
		linkMode_dropDown.selection = g_constraintSettings.linkMode
		posConstraint_checkbox.checked = g_constraintSettings.bPosition
		rotConstraint_checkbox.checked = g_constraintSettings.bRotation
		linkConstraint_checkbox.checked = g_constraintSettings.bLink
		
		-- Sizing Settings
		dropDown_sizingMode.selection = g_sizingSettings.sizingMode
		sizeValue_spinner.value = g_sizingSettings.sizingValue
		
		-- Inclusion
		inclusionMode_dropDown.selection = g_inclusionSettings.inclusionMode
	)
	
	on pickRoot_button picked obj do
	(
		if(obj != undefined and ((classOf obj == Dummy) or (classOf obj == BoneGeometry))) then
		(
			g_helperSettings.rootBone = obj
			format "root bone selected: %\n" g_helperSettings.rootBone
			boneName_label.text = obj.name
		)
		else
		(
			print (classOf obj)
			g_helperSettings.rootBone = undefined
			print "root bone deselected"
			boneName_label.text = ""
		)
		
		rebuildPreview()
	)
	
	function destroyPreview = 
	(
		for helper in g_previewHelpers do
		(
			delete helper
		)
		
		g_previewHelpers = #()
	)
	
	function rebuildPreview = 
	(
		destroyPreview()
		
		local rootBone = g_helperSettings.rootBone
		local zOffset   = g_helperSettings.zOffset
		local size        = g_helperSettings.helperSize
		
		if rootBone == undefined then 
		(
			print "Invalid root bone"
			return undefined
		)
		
		local rootHelper = Point()
		rootHelper.Box = true
		rootHelper.Cross = false
		rootHelper.transform = copy rootBone.transform
		rootHelper.Size = size;
		
		append g_previewHelpers rootHelper
		
		for child in rootBone.children do
		(
			if isValidBone child == true then
			(
				createHelperRecursive child rootHelper zOffset size 0 true
			)
		)
	)
	
	-----------------------------------------------------------------------
	on zOffset_spinner changed val do
	(
		g_helperSettings.zOffset = val
		rebuildPreview()
	)
	
	on helperSize_spinner changed val do
	(
		g_helperSettings.helperSize = val
		rebuildPreview()
	)
	
	on maxDepth_spinner changed val do
	(
		g_helperSettings.maxDepth = val
		rebuildPreview()
	)
	
	on namePrefix_textfield entered text do
	(
		g_helperSettings.namePrefix = text
	)
	
	-----------------------------------------------------------------------
	on linkMode_dropDown selected sel do
	(
		print sel
		g_constraintSettings.linkMode = sel
	)
	on posConstraint_checkbox changed state do
	(
		g_constraintSettings.bPosition = state
	)
	
	on rotConstraint_checkbox changed state do
	(
		g_constraintSettings.bRotation = state
	)
	
	on linkConstraint_checkbox changed state do
	(
		g_constraintSettings.bLink = state
		if(state == true) then
		(
			g_constraintSettings.bRotation = false
			g_constraintSettings.bPosition = false
			posConstraint_checkbox.checked = false
			rotConstraint_checkbox.checked = false
			posConstraint_checkbox.enabled = false
			rotConstraint_checkbox.enabled = false
		)
		else
		(
			posConstraint_checkbox.enabled = true
			rotConstraint_checkbox.enabled = true
		)
	)
	
	-----------------------------------------------------------------------
	on dropDown_sizingMode selected sel do
	(
		g_sizingSettings.sizingMode = sel
		if(sel == SIZE_MODE_FIXED_SIZE) then
		(
			sizeValue_spinner.enabled = false
		)
		else
		(
			sizeValue_spinner.enabled = true
		)
		rebuildPreview()
	)
	
	on sizeValue_spinner changed val do
	(
		g_sizingSettings.sizingValue = val
		rebuildPreview()
	)
	
	-----------------------------------------------------------------------
	on inclusion_list selected sel do
	(
	
	)
	on inclusionMode_dropDown selected sel do
	(
		g_inclusionSettings.inclusionMode = sel
		
		rebuildPreview()
	)
	on listAdd_button picked obj do
	(
		if(classOf obj == BoneGeometry or classOf obj == Dummy) then
		(
			local items = inclusion_list.items
			appendIfUnique items obj.name
			inclusion_list.items = items
		)
		
		rebuildPreview()
	)
	on listRemove_button pressed  do
	(
		local selectedId = inclusion_list.selection
		if (selectedId != undefined and selectedId > 0) then
		(
			inclusion_list.items = deleteItem inclusion_list.items selectedId
		)
		
		rebuildPreview()
	)

	-----------------------------------------------------------------------	
	on generate_button pressed  do
	(
		destroyPreview()

		local rootBone = g_helperSettings.rootBone
		local zOffset   = g_helperSettings.zOffset
		local size        = g_helperSettings.helperSize
		
		if rootBone == undefined then 
		(
			print "Invalid root bone"
			return false
		)
		
		local rootHelper = Point()
		rootHelper.Box = true
		rootHelper.Cross = false
		rootHelper.transform = copy rootBone.transform
		rootHelper.Size = size;
		
		for child in rootBone.children do
		(
			if isValidBone child == true then
			(
				createHelperRecursive child rootHelper zOffset size 0 false
			)
		)
	)
	
	function createHelperRecursive forBone parentHelper zOffset size currDepth preview =
	(
		if(classOf forBone != BoneGeometry and classOf forBone != Dummy) then return false
		
		if (currDepth > g_helperSettings.maxDepth) then return false
			
		local childHelper = Point()
		childHelper.Box = true
		childHelper.Cross = false
		childHelper.transform = copy forBone.transform
		childHelper.Size = getHelperSize currDepth
		childHelper.wirecolor = color 0 255 0
		
		-- Do the Z offset - make sure not to affect the pivot!
		childHelper.objectoffsetpos .z += zOffset
		
		-- Name the helper!
		childHelper.name = makeHelperName(forBone)
		
		-- In preview mode, we do not perform linkage as that is difficult to undo
		if preview == false or preview == undefined then
		(
			if(not needsLinkConstraint(forBone)) then
			(
				if(needsRotationConstraint(forBone)) then
				(
					applyRotationConstraint forBone childHelper
				)
				
				if(needsPositionConstraint(forBone)) then
				(
					applyPositionConstraint forBone childHelper
				)
			)
			else
			(
				-- Link constraint, other constraints and links are inapplicable
				applyLinkConstraint forBone childHelper
			)
			
			-- Do we need to link the helper?
			local linkMode = g_constraintSettings.linkMode
			if linkMode != LINK_MODE_NONE then
			(
				-- Determine the link parent
				local linkTo = undefined

				if 			linkMode == LINK_MODE_ROOT_BONE 			then linkTo = g_helperSettings.rootBone
				else if 	linkMode == LINK_MODE_PARENT_BONE 		then linkTo = forBone.parent
				else if 	linkMode == LINK_MODE_PARENT_HELPER 	then linkTo = parentHelper
				
				applyLinkAttachment childHelper linkTo
			)
		)
		else
		(
			-- In preview mode, add to preview list
			append g_previewHelpers childHelper
		)
		
		
		for child in forBone.children do
		(
			if isValidBone child == true then
			(
				createHelperRecursive child childHelper zOffset size (currDepth+1) preview
			)
		)
	)
	
	------------------------------------------------------------------------------
	-- Helper Functions
	
	function getHelperSize currDepth =
	(
		local mode = g_sizingSettings.sizingMode
		print mode
		print g_sizingSettings.sizingValue
		
		if mode == SIZE_MODE_FIXED_SIZE then return g_helperSettings.helperSize
		else if mode == SIZE_MODE_SCALE_CHILDREN then	return amax 0.01 (g_helperSettings.helperSize * g_sizingSettings.sizingValue ^ (currDepth+1))
		else if mode == SIZE_MODE_FIXED_SCALE_CHILDREN then return amax 0.01 (g_helperSettings.helperSize * g_sizingSettings.sizingValue)
		else if mode == SIZE_MODE_FIXED_SIZE_CHILDREN then return g_sizingSettings.sizingValue
			
		return g_helperSettings.helperSize
	)
	
	function needsRotationConstraint forBone =
	(
		return g_constraintSettings.bRotation
	)
	
	function needsPositionConstraint forBone =
	(
		return g_constraintSettings.bPosition
	)

	function needsLinkConstraint forBone =
	(
		return g_constraintSettings.bLink
	)
	
	function applyRotationConstraint forBone childHelper =
	(
		local orientConstraint = Orientation_Constraint()
		orientConstraint.relative = false -- Keep Initial Offset
		orientConstraint.appendTarget childHelper 100
		
		local rotController = rotation_list()
		forBone.rotation.controller = rotController
		rotController.Available.controller = orientConstraint
	)
	
	function applyPositionConstraint forBone childHelper =
	(
		local posConstraint = Position_Constraint()
		posConstraint.relative = false -- Keep Initial Offset
		posConstraint.appendTarget childHelper 100
		
		local posController = position_list()
		forBone.position.controller = posController -- This ordering MATTERS! Assign the controller THEN the constrain, otherwise the order in the position list messes up
		posController.Available.controller = posConstraint

	)
	
	function applyLinkConstraint forBone childHelper =
	(
		-- must clear out any link attachments first!
		forBone.parent = undefined
		
		local linkController = Link_Constraint()
		forBone.transform.controller = linkController -- ORDER MATTERS! Assign the controller first, THEN add targets
		linkController.addTarget childHelper 0
	)
	
	-- Link attachment (NOT CONSTRAINT!)
	function applyLinkAttachment fromObj toObj =
	(
		format "Applying link attachment from % to %\n" fromObj.name toObj.name
		if isBoneType(toObj) then
		(
			-- needs a constraint
			fromObj.parent = undefined
			
			--local parentTransform = toObj.transform
			--local desiredTransform = parentTransform * inverse parentTransform * fromObj.transform
			--fromObj.transform = desiredTransform
			
			local linkController = Link_Constraint()
			fromObj.transform.controller = linkController -- ORDER MATTERS! Assign the controller first, THEN add targets
			linkController.addTarget toObj 0
		)
		else
		(
			-- simple re-parenting
			fromObj.parent = toObj
		)
	)
	
	function isValidBone forBone =
	(
		-- Perform exclusion/inclusion check
		local found = findItem inclusion_list.items forBone.name
		format "found = %\n" found
		if(g_inclusionSettings.inclusionMode == MODE_INCLUDE) then
		(
			if(found == 0) then return false
			else return true
			
			--return found != 0
		)
		else
		(
			if(found == 0) then return true
			else return false
			--return found == 0
		)
	)
	
	function makeHelperName forBone depth:undefined  =
	(
		local idxSuffix
		if(depth == undefined) then idxSuffix = ""
		else idxSuffix = "_" + depth as string
		
		local nameExpr = g_helperSettings.namePrefix +forBone.name + idxSuffix
		
		return nameExpr
	)
	
	function isBoneType obj =
	(
		return classOf obj == BoneGeometry or classOf obj == Dummy
	)
)

createDialog limbHelperGenerator
limbHelperGenerator.initDefaults()