function Get-VMGuestAction {
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
