function Get-VMGuestConfiguration {
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('VMDeploy.Guest.ConfigurationItem')]
		[string]
		$Identity = '*'
	)
	
	process {
		$($script:configurations.Values | Where-Object Identity -Like $Identity)
	}
}
