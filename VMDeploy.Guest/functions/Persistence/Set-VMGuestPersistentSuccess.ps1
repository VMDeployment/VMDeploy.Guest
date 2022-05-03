function Set-VMGuestPersistentSuccess
{
	<#
	.SYNOPSIS
		Persists the success state of a given configuration item.
	
	.DESCRIPTION
		Persists the success state of a given configuration item.
		This may be used in subsequent tests to skip the actual test run for configuration items configured to use persistence.
		This is mostly used for actions whose results are falsified by subsequent actions in the processing list.
	
	.PARAMETER Identity
		Identity of the configuration item to persist the success state for.
	
	.PARAMETER Value
		Whether the configuration item was actually successful.
	
	.EXAMPLE
		PS C:\> Set-VMGuestPersistentSuccess -Identity $configuration.Identity -Value $true
		
		Sets the specified configuration item as completed successfully.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,

		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[bool]
		$Value
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
		$data = @{ }
		if (Test-Path -Path $configFile) {
			$data = Import-PSFClixml -Path $configFile
		}
		$data[$Identity] = $value
		$data | Export-PSFClixml -Path $configFile
	}
}
