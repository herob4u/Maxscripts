Include "standard_rig_builder.ms"

MacroScript StandardRig
	ButtonText:"Standard Rig"
	Category:"Rig Helpers"
	internalCategory:"Rig Helpers" 
	Tooltip:"Standard Rig"
(	
	on execute do
	(
		createDialog BuildRigDialog
		BuildRigDialog.initDefaults() -- or load if save file found
		BuildRigDialog.rebuildPreview()
	)
)