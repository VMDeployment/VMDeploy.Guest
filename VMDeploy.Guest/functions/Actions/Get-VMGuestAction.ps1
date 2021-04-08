function Get-VMGuestAction {
<#
	.SYNOPSIS
		List the available actions.
	
	.DESCRIPTION
		List the available actions.
		Use Register-VMGuestAction to define new actions.
		Actions implement the logic available to guest configuration entries.
	
	.PARAMETER Name
		Name of the action to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-VMGuestAction
	
		List all available actions.
#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('VMDeploy.Guest.Action')]
		[string]
		$Name = '*'
	)
	
	process {
		$($script:actions.Values | Where-Object Name -Like $Name)
	}
}
