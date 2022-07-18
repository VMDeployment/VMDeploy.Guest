function Test-VMGuestPersistentSuccess
{
	<#
	.SYNOPSIS
		Tests, whether the specified configuration entry has been completed previously.
	
	.DESCRIPTION
		Tests, whether the specified configuration entry has been completed previously.
		This is used in situations where an action that has been completed once will not be validated again.
		Specifically useful when later actions in the task sequence invalidate the result.
	
	.PARAMETER Identity
		Identity of the configuration entry to test.
	
	.PARAMETER Persistent
		Whether the configuration entry uses persistent success flags.
		If this is false, this command will always return $false.
	
	.EXAMPLE
		PS C:\> Test-VMGuestPersistentSuccess -Identity $configuration.Identity -Persistent $configuration.Persistent
		
		Tests, whether the specified configuration entry has been completed successfully.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Identity,

		[Parameter(Mandatory = $true)]
		[bool]
		$Persistent
	)
	
	process
	{
		if (-not $Persistent) { return $false }
		$persistenceData = Get-VMGuestPersistentSuccess
		$persistenceData.$Identity
	}
}
