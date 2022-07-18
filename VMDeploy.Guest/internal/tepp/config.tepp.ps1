Register-PSFTeppScriptblock -Name 'VMDeploy.Guest.ConfigurationItem' -ScriptBlock {
	(Get-VMGuestConfiguration).Identity
}