function Get-VMGuestConfiguration {
<#
	.SYNOPSIS
		List defined guest configuration entries.
	
	.DESCRIPTION
		List defined guest configuration entries.
	
	.PARAMETER Identity
		The identity / name of the guest configuration entry to retrieve.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-VMGuestConfiguration
	
		List all defined guest configuration entries.
#>
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