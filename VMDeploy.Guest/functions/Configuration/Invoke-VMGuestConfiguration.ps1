function Invoke-VMGuestConfiguration {
<#
	.SYNOPSIS
		Apply the currently loaded configuration to the current computer.
	
	.DESCRIPTION
		Apply the currently loaded configuration to the current computer.
		Will respect the order of each entry defined by its weight.
		Each configuration entry will only be executed if the prerequisites are met.
	
	.PARAMETER Restart
		Restart the computer when done processing guest configuration entries.
	
	.PARAMETER MaxInvokeCount
		The maximum number of times this command can run on the current machine.
		Defaults to the configuration setting VMDeploy.Guest.Invoke.MaxRetryCount, which defaults to "10".
		This is to prevent infinite reboot loops during VM deployment.
		To skip this test, use the -Force parameter.
	
	.PARAMETER Force
		Ignore retry count limits on calling Invoke-VMGuestConfiguration.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Invoke-VMGuestConfiguration
		
		Apply the currently loaded configuration to the current computer.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[switch]
		$Restart,
		
		[int]
		$MaxInvokeCount = (Get-PSFConfigValue -FullName 'VMDeploy.Guest.Invoke.MaxRetryCount'),
		
		[switch]
		$Force
	)
	
	begin {
		$currentState = @{ }
		Import-PSFConfig -ModuleName 'VMDeploy.Guest' -ModuleVersion 1
		$currentInvokeCount = Get-PSFConfigValue -FullName 'VMDeploy.Guest.Invoke.CurrentRetryCount'
		
		$die = $false
		if (-not $Force -and $currentInvokeCount -ge $MaxInvokeCount) {
			Write-PSFMessage -Level Host -String 'Invoke-VMGuestConfiguration.InvokeCount.Exceeded' -StringValues $currentInvokeCount, $MaxInvokeCount -Tag interrupt
			$die = $true
		}
	}
	process {
		if ($die) { return }
		
		#region Gather configuration entry state before processing
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Test.Starting'
		foreach ($configuration in Get-VMGuestConfiguration) {
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.Testing' -StringValues $configuration.Identity, $configuration.Action -Target $configuration
			$currentState[$configuration.Identity] = Test-VMGuestConfiguration -Identity $configuration.Identity -Quiet
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.Testing.Completed' -StringValues $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity] -Target $configuration
		}
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Test.Completed'
		#endregion Gather configuration entry state before processing
		
		$configurations = Get-VMGuestConfiguration | Sort-Object Weight, Identity
		Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Processing.Starting'
		foreach ($configuration in $configurations) {
			#region Check Prerequisites
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
			#endregion Check Prerequisites
			
			#region Implement
			Invoke-PSFProtectedCommand -ActionString 'Invoke-VMGuestConfiguration.Configuration.Execute' -ActionStringValues $configuration.Identity, $configuration.Action -ScriptBlock {
				$null = $script:actions[$configuration.Action].ScriptBlock.Invoke($configuration.Parameters)
			} -Target $configuration -Continue
			
			$currentState[$configuration.Identity] = Test-VMGuestConfiguration -Identity $configuration.Identity -Quiet
			Write-PSFMessage -String 'Invoke-VMGuestConfiguration.Configuration.PostAction.Test' -StringValues $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity] -Target $configuration
			#endregion Implement
		}
		
		if ($currentState.Values -notcontains $false) {
			Write-PSFMessage -Level Host -String 'Invoke-VMGuestConfiguration.Finished' -StringValue @($configurations).Count -Tag finished
		}
	}
	end {
		if ($die) { return }
		
		Set-PSFConfig -FullName 'VMDeploy.Guest.Invoke.CurrentRetryCount' -Value ($currentInvokeCount + 1)
		Export-PSFConfig -ModuleName 'VMDeploy.Guest' -ModuleVersion 1
		if ($Restart) { Restart-Computer -Confirm:$false -Force }
	}
}