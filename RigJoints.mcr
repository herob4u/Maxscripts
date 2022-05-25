-- Create Rig Helpers

fileIn "RigJoint_dialog.ms"

Global g_jointSelection = #()
function RigFilterFn obj = 
(
	if(classOf obj == BoneGeometry or classOf obj == Dummy) then
	(
		return findItem g_jointSelection obj == 0
	)
	else return false
)
	
MacroScript RigJoints
	ButtonText:"Rig Joints"
	Category:"Rig Helpers"
	internalCategory:"Rig Helpers" 
	Tooltip:"Rig Joints"
(	
	on execute do
	(
		print "Executing Rig Joints"
		try
		(
			--startTool RigJointTool
			-- Clear the selection at the start of any tool
			g_jointSelection = #()
			local target = PickObject count:1 filter:RigFilterFn message:"Select Starting joint" --Rubberband:selection[1].transform.pos ForceListenerFocus:False
			while target != undefined do
			(
				append g_jointSelection target
				target = PickObject filter:RigFilterFn message:"Select next joint" Rubberband:target.transform.pos 
			)
			
			if queryBox "Create rig from joint selection?" title:"Confirm Selection" then
			(
				-- Display the rollout, and take it from there!
				createDialog RigJointDialog
				RigJointDialog.initDefaults()
				RigJointDialog.selectedJoints = g_jointSelection -- no copies! otherwise will clone the bones
				RigJointDialog.recreateHelpers()
			)
		)
		Catch
		(
			MessageBox "Joint selection not completed" Title:"Failed to create helpers"
		)
	)
)