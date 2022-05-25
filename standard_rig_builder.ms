include "leg_rig_builder.ms"
include "arm_rig_builder.ms"
include "torso_rig_builder.ms"
include "head_rig_builder.ms"

legConfig = LegConfig rigScale:1
armConfig = ArmConfig rigScale:1
headConfig = HeadConfig rigScale:1
torsoConfig = TorsoConfig rigScale:1

rollout BuildRigDialog "Standard Rig Builder" width:632 height:728
(
	local createComHelper, createHipHelper, createRootHelper, rebuildPreview, destroyPreview
	local transientNodes = #()
	
	function isBoneType obj =
	(
		if classOf obj == BoneGeometry or classOf obj == Dummy then
		(
			return true
		)
		else
		(
			return false
		)
	)

	groupBox grp7 "Global Settings" pos:[8,8] width:616 height:112
		spinner globalScale_spinner "Global Scale" pos:[48,32] width:160 height:16 range:[0.001,100,0]
		editText namingPrefix_text "Naming Prefix" pos:[16,56] width:176 height:16
		editText leftMirrorDelimeter_text "Left Mirror Delimeter" pos:[250,64] width:200 height:18
		editText rightMirrorDelimeter_text "Right Mirror Delimeter" pos:[250, 32] width:200 height:18
		pickButton pickPelvis_button "Pick Pelvis" pos:[16,84] width:88 height:24 filter:isBoneType
		pickButton pickHip_button "Pick Hip" pos:[110, 84] width:88 height:24 filter:isBoneType
		
	groupBox grp8 "Head Group" pos:[8,136] width:232 height:136
		spinner headRigScale_spinner "Rig Scale" pos:[48,160] width:80 height:16 range:[0.001,100,0]
		pickButton pickNeck_button "Pick Neck" pos:[16,184] width:72 height:24 filter:isBoneType
		pickButton pickHead_button "Pick Head" pos:[16,216] width:72 height:24 filter:isBoneType
		groupBox grp10 "Head Offset" pos:[136,152] width:88 height:112
			spinner headOffsetX_spinner "X" pos:[160,176] width:48 height:16 range:[-100,100,0]
			spinner headOffsetY_spinner "Y" pos:[160,200] width:48 height:16 range:[-100,100,0]
			spinner headOffsetZ_spinner "Z" pos:[160,224] width:48 height:16 range:[-100,100,0]
			
	groupBox grp11 "Torso Group" pos:[264,136] width:360 height:136
		spinner torsoRigScale_spinner "Rig Scale" pos:[296,160] width:80 height:16 range:[0.001,100,0]
		pickButton pickSpineBegin_button "Pick Spine Begin" pos:[272,184] width:96 height:24 filter:isBoneType
		pickButton pickSpineEnd_button "Pick Spine End" pos:[272,216] width:96 height:24 filter:isBoneType
		editText torsoBonesBaseName_text "Bones Base Name" pos:[400,160] width:208 height:16
		
	groupBox ArmGroup "Arm Group" pos:[8,280] width:616 height:160
		spinner armRigScale_spinner "Rig Scale" pos:[40,296] width:72 height:16 range:[0.001,100,0] filter:isBoneType
		pickButton pickClavicle_button "Pick Clavicle" pos:[16,320] width:88 height:24 filter:isBoneType
		pickButton pickUpperArm_button "Pick Upper Arm" pos:[16,352] width:88 height:24 filter:isBoneType
		pickButton pickHand_button "Pick Hand" pos:[16,384] width:88 height:24 filter:isBoneType
		groupBox grp13 "Manipulators" pos:[120,296] width:144 height:128
		groupBox grp14 "Attributes" pos:[272,296] width:152 height:128
		groupBox grp15 "Twist Controllers" pos:[432,296] width:184 height:128
		spinner elbowSvlMult_spinner "Swivel Multiplier" pos:[296,312] width:115 height:16 range:[0,100,0]
		spinner clavicleOffsetX_spinner "X" pos:[368,344] width:48 height:16 range:[0,100,0]
		spinner clavicleOffsetY_spinner "Y" pos:[368,368] width:48 height:16 range:[0,100,0]
		spinner clavicleOffsetZ_spinner "Z" pos:[368,392] width:48 height:16 range:[0,100,0]
		label lbl2 "Clavicle Offset" pos:[280,344] width:72 height:24
		checkbox twistControllers_checkbox "Generate Twist Controllers" pos:[448,312] width:160 height:24
		checkbox twistLockRotX_checkbox "Lock Rot X" pos:[448,336] width:160 height:16
		checkbox twistLockRotY_checkbox "Lock Rot Y" pos:[448,352] width:160 height:16
		checkbox twistLockRotZ_checkbox "Lock Rot Z" pos:[448,368] width:160 height:16
		pickButton pickIkManip_button "Pick IK Manipulator" pos:[136,320] width:112 height:24
		pickButton pickFkManip_button "Pick FK Manipulator" pos:[136,352] width:112 height:24 toolTip:""

	-- Begin Leg Group
	groupBox grp64 "Leg Group" pos:[8,448] width:616 height:168
		spinner legRigScale_spinner "Rig Scale" pos:[48,464] width:80 height:16 range:[0.001,100,0]
		pickButton pickThigh_button "Pick Thigh" pos:[16,488] width:88 height:24 filter:isBoneType
		pickButton pickFoot_button "Pick Foot" pos:[16,520] width:88 height:24 filter:isBoneType
		pickButton pickToe_button "Pick Toe" pos:[16,552] width:88 height:24 filter:isBoneType
		pickButton pickToeNub_button "Pick Toe Nub" pos:[16,584] width:88 height:24 filter:isBoneType
		groupBox grp65 "Manipulators" pos:[136,464] width:128 height:144
		pickButton pickMasterController_button "Pick Master Controller" pos:[144,488] width:112 height:24
		spinner legOffsetX_spinner "X" pos:[208,536] width:48 height:16 range:[-1000,1000,0]
		spinner legOffsetY_spinner "X" pos:[208,560] width:48 height:16 range:[-1000,1000,0]
		spinner legOffsetZ_spinner "X" pos:[208,584] width:48 height:16 range:[-1000,1000,0]
		label lbl9 "Offset" pos:[144,536] width:48 height:16
		groupBox grp66 "Attributes" pos:[272,464] width:336 height:144
		spinner kneeSwivel_spinner "" pos:[432,504] width:64 height:16 range:[-100,100,0]
		label lbl10 "Enabled" pos:[376,480] width:48 height:16
		label lbl11 "Multiplier" pos:[440,480] width:48 height:16
		label lbl12 "Knee Swivel" pos:[280,504] width:64 height:16
		label lbl13 "Heel Peel" pos:[280,520] width:64 height:16
		label lbl14 "Toe Lift" pos:[280,536] width:64 height:16
		label lbl15 "Toe Tap" pos:[280,552] width:64 height:16
		label lbl16 "Foot Twist" pos:[280,568] width:64 height:16
		checkbox kneeSwivel_checkbox "" pos:[376,504] width:16 height:16
		checkbox heelPeel_checkbox "" pos:[376,520] width:16 height:16
		checkbox toeLift_checkbox "" pos:[376,536] width:16 height:16
		checkbox toeTap_checkbox "" pos:[376,552] width:16 height:16
		checkbox footTwist_checkbox "" pos:[376,568] width:16 height:16
		spinner heelPeel_spinner "" pos:[432,520] width:64 height:16 range:[-100,100,0]
		spinner toeLift_spinner "" pos:[432,536] width:64 height:16 range:[-100,100,0]
		spinner toeTap_spinner "" pos:[432,552] width:64 height:16 range:[-100,100,0]
		spinner footTwist_spinner "" pos:[432,568] width:64 height:16 range:[-100,100,0]
	
	button build_button "BUILD!" pos:[152,640] width:278 height:54

	-- Defaults
	struct DefaultSettings
	(
		-- Globals
		GlobalScale = 1,
		NamingPrefix = "HLP_",
		LeftMirrorDelimeter = "_L_",
		RightMirrorDelimeter = "_R_",
		
		-- Captions
		PickPelvisCaption = "Pick Pelvis",
		PickHipCaption = "Pick Hip",
		PickNeckCaption = "Pick Neck",
		PickHeadCaption = "Pick Head",
		PickSpineBeginCaption = "Pick Spine Begin",
		PickSpineEndCaption = "Pick Spine End",
		PickClavicleCaption = "Pick Clavicle",
		PickUpperArmCaption = "Pick Upper Arm",
		PickHandCaption = "Pick Hand",
		PickIKManipCaption = "Pick IK Manipulator",
		PickFKManipCaption = "Pick FK Manipulator",
		PickThighCaption = "Pick Thigh",
		PickFootCaption = "Pick Foot",
		PickToeCaption = "Pick Toe",
		PickToeNubCaption = "Pick Toe Nub",
		
		-- Spinners
		HeadRigScale = 1,
		TorsoRigScale = 1,
		ArmRigScale = 1,
		LegRigScale = 1,
		ElbowSwivelMult = 1,
		HeadOffsetX = 0,
		HeadOffsetY = 0,
		HeadOffsetZ = 0,
		ClavicleOffsetX = 0,
		ClavicleOffsetY = 0,
		ClavicleOffsetZ = 0,
		KneeSwivelMult = 1,
		HeelPeelMult = 1,
		HeelLiftMult = 1,
		ToeLiftMult = 1,
		ToeTapMult = 1,
		FootTwistMult = 1,
		
		-- Checkboxes
		bGenerateTwistControllers = true,
		bTwistLockRotX = false,
		bTwistLockRotY = false,
		bTwistLockRotZ = false,
		bKneeSwivel = true,
		bHeelPeel = true,
		bHeelLift = true,
		bToeLift = true,
		bToeTap = true,
		bFootTwist = true,
		
		-- Text
		TorsoBonesBaseName = "spine"
	)
	local defaults = DefaultSettings()
	
	local headBuilder = HeadRigBuilder()
	local armBuilder = ArmRigBuilder()
	local torsoBuilder = TorsoRigBuilder()
	local legBuilder = LegRigBuilder()
	
	local isBuilt = false
	
	-- For serialization purposes later
	function loadDefaults =
	(
	)
	
	function initDefaults =
	(
		globalScale_spinner.value 			= defaults.GlobalScale
		namingPrefix_text.text 				= defaults.NamingPrefix
		leftMirrorDelimeter_text.text 		= defaults.LeftMirrorDelimeter
		rightMirrorDelimeter_text.text		= defaults.RightMirrorDelimeter
		
		-- Captions
		pickPelvis_button.caption			= defaults.PickPelvisCaption
		pickHip_button.caption				= defaults.PickHipCaption
		pickNeck_button.caption 			= defaults.PickNeckCaption
		pickHead_button.caption 			= defaults.PickHeadCaption
		pickSpineBegin_button.caption 	= defaults.PickSpineBeginCaption
		pickSpineEnd_button.caption 		= defaults.PickSpineEndCaption
		pickIkManip_button.caption 		= defaults.PickIKManipCaption
		pickFkManip_button.caption 		= defaults.PickFKManipCaption
		pickThigh_button.caption			= defaults.PickThighCaption
		pickFoot_button.caption			= defaults.PickFootCaption
		pickToe_button.caption				= defaults.PickToeCaption
		pickToeNub_button.caption		= defaults.PickToeNubCaption
		
		-- Spinners
		headRigScale_spinner.value 	= defaults.HeadRigScale
		torsoRigScale_spinner.value 	= defaults.TorsoRigScale
		armRigScale_spinner.value 	= defaults.ArmRigScale
		legRigScale_spinner.value		= defaults.LegRigScale
		elbowSvlMult_spinner.value 	= defaults.ElbowSwivelMult
		headOffsetX_spinner.value 	= defaults.HeadOffsetX
		headOffsetY_spinner.value		= defaults.HeadOffsetY
		headOffsetZ_spinner.value		= defaults.HeadOffsetZ
		clavicleOffsetX_spinner.value	= defaults.ClavicleOffsetX
		clavicleOffsetY_spinner.value = defaults.ClavicleOffsetY
		clavicleOffsetZ_spinner.value = defaults.ClavicleOffsetZ
		kneeSwivel_spinner.value		= defaults.KneeSwivelMult
		heelPeel_spinner.value			= defaults.HeelPeelMult
		toeLift_spinner.value			= defaults.ToeLiftMult
		toeTap_spinner.value			= defaults.ToeTapMult
		footTwist_spinner.value		= defaults.FootTwistMult
		
		-- Checkboxes
		twistControllers_checkbox.checked 	= defaults.bGenerateTwistControllers 
		twistLockRotX_checkbox.checked 		= defaults.bTwistLockRotX
		twistLockRotY_checkbox.checked 		= defaults.bTwistLockRotY
		twistLockRotZ_checkbox.checked 		= defaults.bTwistLockRotZ
		kneeSwivel_checkbox.checked			= defaults.bKneeSwivel
		heelPeel_checkbox.checked				= defaults.bHeelPeel
		--heelLift_checkbox.checked				= defaults.bHeelLift
		toeLift_checkbox.checked					= defaults.bToeLift
		toeTap_checkbox	.checked				= defaults.bToeTap
		footTwist_checkbox.checked				= defaults.bFootTwist
		
		-- Text
		torsoBonesBaseName_text.text = defaults.TorsoBonesBaseName
	)
	
	function destroyPreview = 
	(
		for node in transientNodes do
		(
			delete node
		)
		
		transientNodes = #()
	)
	
	function rebuildPreview head: arm: torso: leg: =
	(
		if head == true then ( headBuilder.buildHead headConfig preview:true )
		if arm == true then ( armBuilder.buildArm armConfig preview:true)
		if torso == true then ( torsoBuilder.buildTorso torsoConfig preview:true)
		if leg == true then ( legBuilder.buildLeg legConfig preview:true)
		
		destroyPreview()
	
		createComHelper preview:true
		createHipHelper preview:true
		createRootHelper preview:true
	)
	
	on BuildRigDialog close do
	(
		if not isBuilt then
		(
			headBuilder.destroyPreview()
			armBuilder.destroyPreview()
			torsoBuilder.destroyPreview()
			legBuilder.destroyPreview()
			destroyPreview()
		)
	)
	
	-- Global Settings
	-----------------------------------------------------------------------------
	function getGlobalScale =
	(
		return globalScale_spinner.value
	)
	
	on globalScale_spinner changed val do
	(
		headConfig.rigScale 	= headRigScale_spinner.value * getGlobalScale()
		armConfig.rigScale 	= armRigScale_spinner.value * getGlobalScale()
		torsoConfig.rigScale 	= torsoRigScale_spinner.value * getGlobalScale()
		legConfig.rigScale 	= legRigScale_spinner.value * getGlobalScale()
		
		rebuildPreview head:true arm:true torso:true leg:true
	)
	on namingPrefix_text entered text do
	(
		armConfig.namePrefix = text
		legConfig.namePrefix = text
	)
	
	on pickPelvis_button picked obj do
	(
		pickPelvis_button.caption = obj.name
	)
	on pickPelvis_button rightclick do
	(
		pickPelvis_button.caption = defaults.PickPelvisCaption
	)
	
	on pickHip_button picked obj do
	(
		pickHip_button.caption = obj.name
	)
	on pickHip_button rightclick do
	(
		pickHip_button.caption = defaults.PickHipCaption
	)
	
	function getMirroredBone forBone =
	(
		local boneName
		if classOf forBone == string then boneName = forBone
		else boneName = forBone.name
		
		local leftDelimeter = leftMirrorDelimeter_text.text
		local rightDelimeter = rightMirrorDelimeter_text.text
		
		-- Find out of this bone is mirror-able (i.e has the appropriate delimeter)
		local delimeter
		local leftPattern = "*" + leftDelimeter +"*"
		local rightPattern = "*" + rightDelimeter +"*"
		
		if matchpattern boneName pattern:leftPattern then delimeter = leftDelimeter
		else if matchpattern boneName pattern:rightPattern then delimeter = rightDelimeter
		else return "" -- not mirrorable, return empty bone name
			
		-- find the delimeter substring
		local toDelimeter = undefined
		if delimeter == leftDelimeter then toDelimeter = rightDelimeter
		else toDelimeter = leftDelimeter
		
		local mirroredBoneName = substituteString  boneName delimeter toDelimeter
		if mirroredBoneName == boneName then return ""
			
		return mirroredBoneName
	)
	
	-- returns 0 if not a sided bone
	-- 1 if left side
	-- 2 if right side
	function getBoneSide boneName =
	(
		local leftDelimeter = leftMirrorDelimeter_text.text
		local rightDelimeter = rightMirrorDelimeter_text.text
		
		local leftPattern = "*" + leftDelimeter +"*"
		if matchpattern boneName pattern:leftPattern then return 1
			
		local rightPattern = "*" + rightDelimeter +"*"
		if matchpattern boneName pattern:rightPattern then return 2
		
		return 0
	)
	
	function createHipHelper preview:false =
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
			
		local forBone = execute ("$'"+pickHip_button.caption + "'")

		if forBone == undefined then
		(
			print "Failed to create helper, invalid bone"
			return undefined
		)
		
		local radius = 8 * getGlobalScale()
		local thickness = 0.4  * getGlobalScale()
		local helper = Circle()
		
		helper.radius = radius
		helper.render_displayRenderMesh = true -- Enable in Viewport
		helper.render_thickness  = thickness
		helper.render_sides = 7
		helper.wirecolor = color 10 18 33
		
		helper.transform = copy forBone.transform
		helper.objectoffsetrot = EulerAngles 90 0 0
		
		helper.name = namingPrefix_text.text + "Hip"
		
		if not isPreview then
		(
			-- Perform constraints
			orientationConstraint forBone helper
			--positionConstraint forBone helper
		)
		
		append transientNodes helper
		
		return helper
	)
	
	function createComHelper preview:false =
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview
			
		local forBone = execute ("$'"+pickPelvis_button.caption + "'")

		if forBone == undefined then
		(
			print "Failed to create helper, invalid bone"
			return undefined
		)
		
		local radius = 10 * getGlobalScale()
		local thickness = 0.3  * getGlobalScale()
		local helper = Circle()
		
		helper.radius = radius
		helper.render_displayRenderMesh = true -- Enable in Viewport
		helper.render_thickness  = thickness
		helper.render_sides = 7
		helper.wirecolor = color 255 255 0
		
		helper.transform = copy forBone.transform
		helper.objectoffsetrot = EulerAngles 90 0 0
		
		helper.name = namingPrefix_text.text + "COM"
		
		-- Perform constraints
		if not isPreview then
		(
			orientationConstraint forBone helper
			positionConstraint forBone helper
		)
		
		append transientNodes helper
		
		return helper
	)
	
	function createRootHelper preview:false =
	(
		-- For MaxScript's retarded lack of default function parameters
		local isPreview = false
		if preview != unsupplied then isPreview = preview

		local helper = Ngon()
		helper.nsides = 3
		helper.radius = 10 * getGlobalScale()
		helper.cornerRadius = 2 * getGlobalScale()
		helper.render_displayRenderMesh = true -- Enable in Viewport
		helper.render_thickness  = 0.1 * getGlobalScale()
		helper.render_sides = 7
		helper.wirecolor = color 255 255 0
		
		helper.position = [0, 0, 0]
		helper.rotation = EulerAngles 0 0 90
		
		helper.name = namingPrefix_text.text + "Root"
		
		append transientNodes helper
		
		return helper
	)
	
	-- Head Group
	-----------------------------------------------------------------------------
	on pickNeck_button picked obj do
	(
		headConfig.neck = obj.name
		pickNeck_button.caption = obj.name
		rebuildPreview head:true
	)
	on pickNeck_button rightclick do
	(
		headConfig.neck = ""
		pickNeck_button.caption = defaults.PickNeckCaption
		rebuildPreview head:true
	)
	on pickHead_button picked obj do
	(
		headConfig.head = obj.name
		pickHead_button.caption = obj.name
		rebuildPreview head:true
	)
	on pickHead_button rightclick do
	(
		headConfig.head = ""
		pickHead_button.caption = defaults.PickHeadCaption
		rebuildPreview head:true
	)
	on headRigScale_spinner changed val do 
	( 
		headConfig.rigScale 	= headRigScale_spinner.value * getGlobalScale()
		rebuildPreview head:true
	)

	on headOffsetX_spinner changed val do 
	( 
		headConfig.headOffset.x = val 
		rebuildPreview head:true
	)
			
	on headOffsetY_spinner changed val do 
	( 
		headConfig.headOffset.y = val 
		rebuildPreview head:true
	)
	on headOffsetZ_spinner changed val do 
	( 
		headConfig.headOffset.z = val 
		rebuildPreview head:true 
	)
	
	-- Torso Group
	-----------------------------------------------------------------------------
	on torsoRigScale_spinner changed val do
	(
		torsoConfig.rigScale 	= torsoRigScale_spinner.value * getGlobalScale()
		rebuildPreview torso:true
	)
	on pickSpineBegin_button picked obj do
	(
		pickSpineBegin_button.caption = obj.name
		torsoConfig.spineBegin = obj.name
		rebuildPreview torso:true
	)
	on pickSpineBegin_button rightclick do
	(
		pickSpineBegin_button.caption = defaults.PickSpineBeginCaption
		torsoConfig.spineBegin = ""
		rebuildPreview torso:true
	)
	on pickSpineEnd_button picked obj do
	(
		pickSpineEnd_button.caption = obj.name
		torsoConfig.spineEnd = obj.name
		rebuildPreview torso:true
	)
	on pickSpineEnd_button rightclick do
	(
		pickSpineEnd_button.caption = defaults.PickSpineEndCaption
		torsoConfig.spineEnd = ""
		rebuildPreview torso:true
	)

	-- Arm Group
	-----------------------------------------------------------------------------
	on armRigScale_spinner changed val do
	(
		armConfig.rigScale 	= armRigScale_spinner.value * getGlobalScale()
		rebuildPreview arm:true
	)
	
	on pickClavicle_button picked obj do
	(
		armConfig.clavicle = obj.name
		pickClavicle_button.caption = obj.name
		rebuildPreview arm:true
	)
	on pickClavicle_button rightclick do
	(
		armConfig.clavicle = ""
		pickClavicle_button.caption = defaults.PickClavicleCaption
		rebuildPreview arm:true
	)
	
	on pickUpperArm_button picked obj do
	(
		armConfig.upperArm = obj.name
		pickUpperArm_button.caption = obj.name
		rebuildPreview arm:true
	)
	on pickUpperArm_button rightclick do
	(
		armConfig.upperArm = ""
		pickUpperArm_button.caption = defaults.PickUpperArmCaption
		rebuildPreview arm:true
	)
	
	on pickHand_button picked obj do
	(
		armConfig.hand = obj.name
		pickHand_button.caption = obj.name
		rebuildPreview arm:true
	)
	on pickHand_button rightclick do
	(
		armConfig.hand = ""
		pickHand_button.caption = defaults.PickHandCaption
		rebuildPreview arm:true
	)
	
	on elbowSvlMult_spinner changed val do ( armConfig.elbowSwivelMult = val )
	on clavicleOffsetX_spinner changed val do 
	(	
		armConfig.clavicleOffset.x = val 
		rebuildPreview arm:true
	)
	on clavicleOffsetY_spinner changed val do 
	( 
		armConfig.clavicleOffset.y = val 
		rebuildPreview arm:true
	)
	on clavicleOffsetZ_spinner changed val do 
	( 
		armConfig.clavicleOffset.z = val
		rebuildPreview arm:true
	)
	
	on twistControllers_checkbox changed state do 
	( 
		armConfig.bTwistControllers = state 
		rebuildPreview arm:true
	)
	on twistLockRotX_checkbox changed state do ( armConfig.twistRotLock[BIT_LOCK_ROT_X] = state )
	on twistLockRotY_checkbox changed state do ( armConfig.twistRotLock[BIT_LOCK_ROT_Y] = state )
	on twistLockRotZ_checkbox changed state do ( armConfig.twistRotLock[BIT_LOCK_ROT_Z] = state )
	
	on pickIkManip_button picked obj do
	(
		armConfig.ikManipTemplate = obj
		pickIkManip_button.caption = obj.name
		rebuildPreview arm:true
	)
	on pickIkManip_button rightclick do
	(
		armConfig.ikManipTemplate = undefined
		pickIkManip_button.caption = defaults.PickIkManipCaption
		rebuildPreview arm:true
	)
	on pickFkManip_button picked obj do
	(
		armConfig.fkRotatorTemplate = obj
		pickFkManip_button.caption = obj.name
		rebuildPreview arm:true
	)
	on pickFkManip_button rightclick do
	(
		armConfig.fkRotatorTemplate = undefined
		pickFkManip_button.caption = defaults.PickFkManipCaption
		rebuildPreview arm:true
	)
	
	-- Leg Group
	-----------------------------------------------------------------------------
	on legRigScale_spinner changed val do
	(
		legConfig.rigScale 	= legRigScale_spinner.value * getGlobalScale()
		rebuildPreview leg:true
	)
	
	on pickThigh_button picked obj do
	(
		legConfig.thigh = obj.name
		pickThigh_button.caption = obj.name
		rebuildPreview leg:true
	)
	on pickThigh_button rightclick do
	(
		legConfig.thigh =""
		pickThigh_button.caption = defaults.PickThighCaption
		rebuildPreview leg:true
	)
	
	on pickFoot_button picked obj do
	(
		legConfig.foot = obj.name
		pickFoot_button.caption = obj.name
		rebuildPreview leg:true
	)
	on pickFoot_button rightclick do
	(
		legConfig.foot = ""
		pickFoot_button.caption = defaults.PickFootCaption
		rebuildPreview leg:true
	)
	
	on pickToe_button picked obj do
	(
		legConfig.toe = obj.name
		pickToe_button.caption = obj.name
		rebuildPreview leg:true
	)
	on pickToe_button rightclick do
	(
		legConfig.toe = ""
		pickToe_button.caption = defaults.PickToeCaption
		rebuildPreview leg:true
	)
	
	on pickToeNub_button picked obj do
	(
		legConfig.toeNub = obj.name
		pickToeNub_button.caption = obj.name
		rebuildPreview leg:true
	)
	on pickToeNub_button rightclick do
	(
		legConfig.toeNub = ""
		pickToeNub_button.caption = defaults.PickToeNubCaption
		rebuildPreview leg:true
	)
	
	on pickMasterController_button picked obj do 
	( 
		legConfig.legMasterController = obj
		rebuildPreview leg:true
	)
	on pickMasterController_button rightclick  do 
	( 
		legConfig.legMasterController = undefined 
		rebuildPreview leg:true
	)
	
	on legOffsetX_spinner changed val do 
	( 
		legConfig.legMasterOffset.x = val
		rebuildPreview leg:true
	)
	on legOffsetY_spinner changed val do
	( 
		legConfig.legMasterOffset.y = val
		rebuildPreview leg:true
	)
	on legOffsetZ_spinner changed val do
	( 
		legConfig.legMasterOffset.z = val
		rebuildPreview leg:true
	)
	
	on kneeSwivel_checkbox changed status do ( legConfig.bKneeSwivel = status )
	on heelPeel_checkbox changed status do ( legConfig.bHeelPeel = status )
	on toeLift_checkbox changed status do ( legConfig.bToeLift = status )
	on toeTap_checkbox changed status do ( legConfig.bToeTap = status )
	on footTwist_checkbox changed status do ( legConfig.bFootTwist = status )
	
	on kneeSwivel_spinner changed val do ( legConfig.kneeSwivelMult = val )
	on heelPeel_spinner changed val do ( legConfig.heelPeelMult = val )
	on toeLift_spinner changed val do ( legConfig.toeLiftMult = val )
	on toeTap_spinner changed val do ( legConfig.toeTapMult = val )
	on footTwist_spinner changed val do ( legConfig.footTwistMult = val )
	
	-- BUILD! 
	-----------------------------------------------------------------------------
	on build_button pressed  do
	(
		undo on
		--local headBuilder = HeadRigBuilder()
		--local torsoBuilder = TorsoRigBuilder()
		--local armBuilder	= ArmRigBuilder()
		--local legBuilder	= LegRigBuilder()
		
		-- Destroy the preview of global controllers (Hip, Master, etc)
		destroyPreview()
		
		local armBoneSide = getBoneSide armConfig.clavicle
		local legBoneSide = getBoneSide legConfig.thigh
		
		local namePrefix = namingPrefix_text.text
		
		if armBoneSide == 1 then -- Left
		(
			armConfig.namePrefix = namePrefix + "L_"
		)
		else if armBoneSide == 2 then -- Right
		(
			armConfig.namePrefix = namePrefix + "R_"
		)
		
		if legBoneSide == 1 then -- Left
		(
			legConfig.namePrefix = namePrefix + "L_"
		)
		else if armBoneSide == 2 then -- Right
		(
			legConfig.namePrefix = namePrefix + "R_"
		)
		
		headBuilder.buildHead headConfig
		torsoBuilder.buildTorso torsoConfig
		armBuilder.buildArm armConfig
		legBuilder.buildLeg legConfig
		
		local mirroredArmConfig = copy armConfig
		mirroredArmConfig.clavicle = getMirroredBone armConfig.clavicle
		mirroredArmConfig.upperArm = getMirroredBone armConfig.upperArm
		mirroredArmConfig.hand = getMirroredBone armConfig.hand
		
		local mirroredLegConfig = copy legConfig
		mirroredLegConfig.thigh = getMirroredBone legConfig.thigh
		mirroredLegConfig.foot = getMirroredBone legConfig.foot
		mirroredLegConfig.toe = getMirroredBone legConfig.toe
		mirroredLegConfig.toeNub = getMirroredBone legConfig.toeNub
		
		-- Mirror the convention
		if armBoneSide == 1 then -- Left
		(
			mirroredArmConfig.namePrefix = namePrefix + "R_"
		)
		else if armBoneSide == 2 then -- Right
		(
			mirroredArmConfig.namePrefix = namePrefix + "L_"
		)
		
		if legBoneSide == 1 then -- Left
		(
			mirroredArmConfig.namePrefix = namePrefix + "R_"
		)
		else if armBoneSide == 2 then -- Right
		(
			mirroredArmConfig.namePrefix = namePrefix + "L_"
		)
		
		armBuilder.buildArm mirroredArmConfig
		legBuilder.buildLeg mirroredLegConfig
		
		-- Create the remaining core controllers (COM, Hips, Root, etc)
		local comHelper = createComHelper()
		local hipHelper = createHipHelper()
		local rootHelper = createRootHelper()
		
		isBuilt = true
		--  Build mirrored parts
		--armBuilder.buildArm armConfig
		--legBuilder.buildLeg legConfig
	)
)

--createDialog BuildRigDialog
--BuildRigDialog.initDefaults()