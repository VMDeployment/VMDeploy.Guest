function Unregister-VMGuestAction {
<#
	.SYNOPSIS
		Removes a registered guest action.
	
	.DESCRIPTION
		Removes a registered guest action.
		Actions implement the logic available to guest configuration entries.
		Removing an action will break all configuration entries using it.
		Actions can be updated/overwritten without needing to actually remove it.
		This command is intended primarily as a way to clear the current state when starting a new test/debug run with externally defined actions.
	
	.PARAMETER Name
		Name of the action to remove.
	
	.EXAMPLE
		PS C:\> Get-VMGuestAction | Unregister-VMGuestAction
	
		Clear all configured guest actions.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('VMDeploy.Guest.Action')]
		[string[]]
		$Name
	)
	
	process {
		foreach ($nameEntry in $Name) {
			$script:actions.Remove($nameEntry)
		}
	}
}
