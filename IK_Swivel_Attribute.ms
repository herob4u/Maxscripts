IK_Swivel_Attribute = attributes custom_Attributes
(
	parameters params rollout:IKSwivelRollout
	(
		enabled type:#boolean ui:enabledBtn default:false
		ikChainName type:#string ui:ikChainName default:""
	)
		
	rollout IKSwivelRollout "IK Swivel"
	(		
		function isIkType obj =
		(
			if(classOf obj == IK_Chain_Object) then
			(
				return true
			)
			return false
		)
		
		checkbox enabledBtn "Enabled" width:64 height:16
		edittext ikChainName "IK Name" width:128 height:16 readonly:true
		pickButton pickIk_button "Pick IK Chain" width:88 height:24 filter:isIkType

		local targetIkChain = undefined
		
		function pickIkChain ikChain =
		(
			targetIkChain = ikChain
			if(targetIkChain != undefined) then
			(
				pickIk_button.text = targetIkChain.name
				ikChainName.text = targetIkChain.name;

			)
			else
			(
				pickIk_button.text = "Pick IK Chain"
				ikChainName.text = "";
			)
		)
		
		function getIkChain =
		(
			print "getting IK chain"
			local ikChain = execute ("$'"+ ikChainName.text + "'")
			return ikChain
		)

		on enabledBtn changed state do
		(
			print "enable btn changed"
			local ikChain = getIkChain()
			if(ikChain != undefined and isIkType ikChain) then 
			(
				ikChain.transform.controller.useVHTarget = state
			)
		)
		
		on pickIk_button picked obj do
		(
			pickIkChain obj
			
			local ikChain = getIkChain()
			if(ikChain != undefined and isIkType ikChain) then
			(
				ikChain.transform.controller.useVHTarget = enabledBtn.checked
				ikChainName.text = targetIkChain.name;
			)
		)
	)
)

for obj in $ do
(
	if(classOf(obj.modifiers[1]) == EmptyModifier) then
	(
		local attr = custAttributes.add obj.modifiers[1] IK_Swivel_Attribute
		print "added attrib"
	)
	else
	(
		print "Not an attribute holder"
	)
)
