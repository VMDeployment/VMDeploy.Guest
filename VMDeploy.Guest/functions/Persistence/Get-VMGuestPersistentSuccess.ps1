function Get-VMGuestPersistentSuccess
{
	<#
	.SYNOPSIS
		Returns the various success states of configuration items.
	
	.DESCRIPTION
		Returns the various success states of configuration items.
		Configuration items that have been verified as successfully completed persist that information,
		so that subsequent tests need not be executed and later alterations to the state of the machine
		do not affect the test results.
	
	.EXAMPLE
		PS C:\> Get-VMGuestPersistentSuccess
		
		Returns a list of all persisted configuration items and their completion state
	#>
	[OutputType([hashtable])]
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		$configPath = Join-Path -Path (Get-PSFPath -Name AppData) -ChildPath 'VMDeploy\Guest'
		if (-not (Test-Path -Path $configPath)) {
			$null = New-Item -Path $configPath -ItemType Directory -Force
		}
		$configFile = Join-Path -Path $configPath -ChildPath 'persistence.clidat'
	}
	process
	{
		if (Test-Path -Path $configFile) {
			Import-PSFClixml -Path $configFile
		}
		else { @{ } }
	}
}
