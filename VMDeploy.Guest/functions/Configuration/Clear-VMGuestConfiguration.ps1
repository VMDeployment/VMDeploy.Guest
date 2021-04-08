function Clear-VMGuestConfiguration {
<#
	.SYNOPSIS
		Remove all defined guest configuration entries.
	
	.DESCRIPTION
		Remove all defined guest configuration entries.
	
	.EXAMPLE
		PS C:\> Clear-VMGuestConfiguration
	
		Removes all defined guest configuration entries.
#>
	[CmdletBinding()]
	param ()
	
	process {
		$script:configurations.Clear()
	}
}
