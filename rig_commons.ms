-- Rig commons

BIT_LOCK_POS_X = 1
BIT_LOCK_POS_Y = 2
BIT_LOCK_POS_Z = 3
BIT_LOCK_ROT_X = 4
BIT_LOCK_ROT_Y = 5
BIT_LOCK_ROT_Z = 6

-- Creates an orientation constraint for _obj being controlled by _toTarget
-- returns the orientation constraint controller after it has been assigned
function orientationConstraint _obj _toTarget =
(
	if _obj == undefined or _toTarget == undefined then return undefined
		
	if _obj == _toTarget then return undefined
		
	
	local orientConstraint = Orientation_Constraint()
	orientConstraint.relative = false -- Keep Initial Offset
	orientConstraint.appendTarget _toTarget 100
	
	local rotController = _obj.rotation.controller
	if classOf rotController != rotation_list then
	(
		rotController = rotation_list()
		_obj.rotation.controller = rotController
	)
	
	rotController.Available.controller = orientConstraint
	
	return orientConstraint
)

function positionConstraint _obj _toTarget =
(
	if _obj == undefined or _toTarget == undefined then return undefined
		
	if _obj == _toTarget then return undefined
		
	local posConstraint = Position_Constraint()
	posConstraint.relative = false -- Keep Initial Offset
	posConstraint.appendTarget _toTarget 100
	
	local posController = _obj.rotation.controller
	if classOf posController != position_list then
	(
		posController = position_list()
		_obj.position.controller = posController -- This ordering MATTERS! Assign the controller THEN the constrain, otherwise the order in the position list messes up
	)
	
	posController.Available.controller = posConstraint
	
	return posConstraint
)

function linkConstraint _obj _toTarget =
(
	format "Link Constaint between % and %" _obj.name _toTarget.name
	-- must clear out any link attachments first!
	_obj.parent = undefined
	
	local linkController = Link_Constraint()
	_obj.transform.controller = linkController -- ORDER MATTERS! Assign the controller first, THEN add targets
	linkController.addTarget _toTarget 0
)

-- Returns true if bone1 can reach bone2 - i.e they belong to the same hierarchy
function areBonesConnected _bone1 _bone2 =
(
	local bone1
	local bone2
	
	if classOf _bone1 == string and classOf _bone2 == string then
	(
		bone1 = execute ("$'"+_bone1 + "'")
		bone2 = execute ("$'"+_bone2+ "'")
	)
	else
	(
		bone1 = _bone1
		bone2 = _bone2
	)

	
	if bone1 == undefined or bone2 == undefined then 
	(
		print "failed to get bones, undefined"
		return false
	)
	
	-- Base case
	if bone1 == bone2 then
	(
		print "found!"
		return true
	)
	
	-- Recurse on all children
	for child in bone1.children do
	(			
		if(areBonesConnected child bone2) then return true
	)
	
	return false
)

-- Returns true if bone1 can reach bone2 - i.e they belong to the same hierarchy
function getTraversalPath _bone1 _bone2 &_outTraversal =
(
	local bone1
	local bone2
	
	if classOf _bone1 == string and classOf _bone2 == string then
	(
		bone1 = execute ("$'"+_bone1 + "'")
		bone2 = execute ("$'"+_bone2+ "'")
	)
	else
	(
		bone1 = _bone1
		bone2 = _bone2
	)

	
	if bone1 == undefined or bone2 == undefined then 
	(
		print "failed to get bones, undefined"
		return false
	)
	
	-- Base case
	if bone1 == bone2 then
	(
		print "found!"
		return true
	)
	
	-- Recurse on all children
	for child in bone1.children do
	(			
		if(getTraversalPath child bone2 &_outTraversal) then 
		(
			append _outTraversal child
			return true
		)
	)
	
	return false
)

function makeIk bone1 bone2 =
(
	NIK = iksys.ikchain bone1 bone2 "IKHISolver"
	return NIK
)

function freezeTransforms _obj =
(
	local CurObj = _obj	

	if classof CurObj.rotation.controller != Rotation_Layer do
	(
		CurObj.rotation.controller = Euler_Xyz() 		
		CurObj.rotation.controller = Rotation_list() 			
		CurObj.rotation.controller.available.controller = Euler_xyz() 		
		CurObj.rotation.controller.setname 1 "Frozen Rotation" 		
		CurObj.rotation.controller.setname 2 "Zero Euler XYZ" 		
		CurObj.rotation.controller.SetActive 2 		
	)
	if classof CurObj.position.controller != Position_Layer do
	(
		CurObj.position.controller = Bezier_Position() 			
		CurObj.position.controller = position_list() 			
		CurObj.position.controller.available.controller = Position_XYZ() 	
		CurObj.position.controller.setname 1 "Frozen Position" 	
		CurObj.position.controller.setname 2 "Zero Pos XYZ" 			
		CurObj.position.controller.SetActive 2 		
		CurObj.Position.controller[2].x_Position = 0
		CurObj.Position.controller[2].y_Position = 0
		CurObj.Position.controller[2].z_Position = 0
	)
)

function findSymmetricBone forBone delimeter startBone: =
(
	if forBone == undefined then
	(
		print "Failed to find symmetric bone. Invalid bone provided"
		return undefined
	)
	
	local start = undefined
	if(startBone != undefined or startBone != unsupplied) then 
	(
		start = startBone
	)
	
	if classOf forBone == string then
	(
		start = execute ("$'"+forBone + "'")
	)
	else
	(
		start = forBone
	)
	
	-- Begin the search! Traverse through parents and see if they house 
)
