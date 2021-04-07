function Invoke-VMGuestConfiguration {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[switch]
		$Restart
	)
	
	begin {
		$currentState = @{ }
	}
	process {
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Test.Starting'
		foreach ($configuration in Get-VMGuestConfiguration) {
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.Testing' -StringValues $configuration.Identity, $configuration.Action -Target $configuration
			$currentState[$configuration.Identity] = Test-VMGuestConfiguration -Identity $configuration.Identity -Quiet
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.Testing.Completed' -StringValues $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity] -Target $configuration
		}
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Test.Completed'
		
		$configurations = Get-VMGuestConfiguration | Sort-Object Weight, Identity
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Processing.Starting'
		foreach ($configuration in $configurations) {
			Write-PSFMessage -Level Host -String 'Invoke-VMGuestConfiguration.Configuration.Processing' -StringValues $configuration.Identity, $configuration.Action -Target $configuration
			if ($currentState[$configuration.Identity]) {
				Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.DoneSkipping' -StringValues $configuration.Identity, $configuration.Action -Target $configuration
				continue
			}
			
			if (-not $script:actions[$configuration.Action]) {
				Write-PSFMessage -Level Warning -String 'Invoke-VMGuestConfiguration.Configuration.ActionMissing' -StringValues $configuration.Identity, $configuration.Action -Target $configuration
				continue
			}
			
			foreach ($dependency in $configuration.DependsOn) {
				if (-not $currentState[$dependency]) {
					Write-PSFMessage -Level Warning -String 'Invoke-VMGuestConfiguration.Configuration.DependencyNotDone' -StringValues $configuration.Identity, $configuration.Action, $dependency -Target $configuration
					continue
				}
			}
			
			Invoke-PSFProtectedCommand -ActionString 'Invoke-VMGuestConfiguration.Configuration.Execute' -ActionStringValues $configuration.Identity, $configuration.Action -ScriptBlock {
				$null = $script:actions[$configuration.Action].ScriptBlock.Invoke($configuration.Parameters)
			} -Target $configuration -Continue
			
			$currentState[$configuration.Identity] = Test-VMGuestConfiguration -Identity $configuration.Identity -Quiet
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.PostAction.Test' -StringValues $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity] -Target $configuration
		}
		
		if ($currentState.Values -notcontains $false) {
			Write-PSFMessage -Level Host -String 'Invoke-VMGuestConfiguration.Finished' -StringValue @($configurations).Count -Tag finished
		}
	}
	end {
		if ($Restart) { Restart-Computer }
	}
}