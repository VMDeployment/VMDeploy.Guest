function Test-VMGuestConfiguration {
<#
	.SYNOPSIS
		Tests whether a given configuration entry has been successfully applied.
	
	.DESCRIPTION
		Tests whether a given configuration entry has been successfully applied.
	
	.PARAMETER Identity
		The identity of the configuration entry to test.
		Defaults to '*'
	
	.PARAMETER Quiet
		Do not return a result object, instead only return $true or $false
	
	.EXAMPLE
		PS C:\> Test-VMGuestConfiguration
	
		Tests for each defined configuration entry, whether it has been successfully applied.
#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('VMDeploy.Guest.ConfigurationItem')]
		[string]
		$Identity = '*',
		
		[switch]
		$Quiet
	)
	
	process {
		foreach ($configuration in Get-VMGuestConfiguration -Identity $Identity) {
			$result = [PSCustomObject]@{
				ConfigurationObject = $configuration
				PSTypeName		    = 'VMDeploy.Guest.Configuration.TestResult'
				Identity		    = $configuration.Identity
				Action			    = $configuration.Action
				Success			    = $false
				Type			    = 'Not Started'
				Data			    = $null
			}
			
			#region Action Missing
			if (-not $script:actions[$configuration.Action]) {
				$result.Type = 'Missing Action'
				if ($Quiet) { $result.Success }
				else { $result }
				continue
			}
			#endregion Action Missing

			#region Persistence
			if (Test-VMGuestPersistentSuccess -Identity $configuration.Identity -Persistent $configuration.Persistent) {
				$result.Type = 'Success (Persisted)'
				$result.Success = $true
				if ($Quiet) { $result.Success }
				else { $result }
				continue
			}
			#endregion Persistence
			
			#region Process Validation Script
			try {
				$validateResult = $script:actions[$configuration.Action].Validate.Invoke($configuration.Parameters) | Where-Object {
					$_ -is [bool]
				} | Select-Object -Last 1
			}
			catch {
				$result.Type = 'Error'
				$result.Data = $_
				if ($Quiet) { $result.Success }
				else { $result }
				continue
			}
			
			$result.Success = $validateResult
			if ($validateResult) {
				$result.Type = 'Success'
				Set-VMGuestPersistentSuccess -Identity $configuration.Identity -Value $true
			}
			else {
				$result.Type = 'Not Completed'
			}
			if ($Quiet) { $result.Success }
			else { $result }
			#endregion Process Validation Script
		}
	}
}