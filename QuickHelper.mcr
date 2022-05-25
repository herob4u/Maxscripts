-- Quick Helper
Include "rig_commons.ms"
Include "QuickHelper_dialog.ms"

Global g_quickHelpers = #()

function quickHelperFilterFn obj =
(
	return classOf obj == BoneGeometry or classOf obj == Dummy or classOf obj == Point
)

MacroScript QuickHelper
	ButtonText:"Quick Helper"
	Category:"Rig Helpers"
	internalCategory:"Rig Helpers" 
	Tooltip:"Quick Helper"
(	
	on execute do
	(
		print "Executing Quick Helper"
		--try
		(
			-- Present the dialog to configure the helpers
			createDialog QuickHelperDialog
			QuickHelperDialog.initDefaults()
			
			g_quickHelpers = #()
			local target = PickObject count:1 filter:quickHelperFilterFn message:"Select Starting joint" --Rubberband:selection[1].transform.pos ForceListenerFocus:False
			while target != undefined do
			(
				-- Do stuff with target
				
				-- If we selected a helper, see if it's one we added. Remove it if that is the case
				if classOf target == Point then
				(
					local foundIdx = findItem g_quickHelpers target
					if foundIdx != 0 then
					(
						deleteItem g_quickHelpers foundIdx
						delete target
					)
				)
				else
				(
					-- We selected a new bone, rig it! We will defer this to our UI later on. aka QuickRigDialog.CreateHelper forBone
					local helper = QuickHelperDialog.spawnHelper target
					
					append g_quickHelpers helper
				)
				-- Select next
				target = PickObject filter:quickHelperFilterFn message:"Select a joint to rig, or a helper to remove"
			)
			
			-- Finished picking, commit
			QuickHelperDialog.commit()
			destroyDialog QuickHelperDialog
		)
-- 		Catch
-- 		(
-- 			MessageBox "Joint selection not completed" Title:"Failed to create helpers"
-- 		)
	)
)