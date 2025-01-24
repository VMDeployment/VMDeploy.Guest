Register-PSFTeppScriptblock -Name 'VMDeploy.Guest.Action' -ScriptBlock {
	(Get-VMGuestAction).Name
}