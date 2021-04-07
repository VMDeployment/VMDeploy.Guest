function Test-VMGuestConfiguration {
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
				$result.TypeNames = 'Missing Action'
				if ($Quiet) { $result.Success }
				else { $result }
				continue
			}
			#endregion Action Missing
			
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