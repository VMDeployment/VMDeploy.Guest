function Register-VMGuestConfiguration {
<#
	.SYNOPSIS
		Register a new guest configuration entry.
	
	.DESCRIPTION
		Register a new guest configuration entry.
		These are used to define the desired state of the target machine.
		Each configuration entry references the action that implements it:
		- Ensure the action exists (use "Get-VMGuestAction" to verify if in doubt)
		- Each action might require parameters. Check the required parameters and rovide at least all the mandatory parameters.
	
	.PARAMETER Identity
		Name or ID of the configuration entry.
		This will be used in all the logs, so make sure it is a useful label.
	
	.PARAMETER Weight
		The weight of a configuration entry governs its processing order.
		The lower the number, the sooner it will be applied.
		Defaults to "50"
	
	.PARAMETER Action
		Name of the action that implements the configuration entry.
	
	.PARAMETER Parameters
		Parameters to provide to the action when executing or validating.
	
	.PARAMETER DependsOn
		Other configuration entries that must have been applied before this configuration entry can be executed.
		For example, imagine a configuration entry that wants to ensure all updates provided via SCCM have been installed:
		That example configuration could not possibly succeed before the SCCM client has been installed and configured.
	
	.PARAMETER Source
		Documentation only.
		Where a given configuration entry comes from.
		Used to track the source in the logging, but has no technical impact on processing.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Register-VMGuestConfiguration -Identity 'Folder_Scripts' -Action 'NewFolder' -Parameters @{ Path = 'C:\Scripts' }
	
		Defines a new configuration entry, ensuring a scripts folder gets created if missing.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]
		$Weight = 50,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('VMDeploy.Guest.Action')]
		[PsfValidateSet(TabCompletion = 'VMDeploy.Guest.Action')]
		[string]
		$Action,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Hashtable]
		$Parameters = @{ },
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DependsOn = @(),
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Source = '<unknown>',
		
		[switch]
		$EnableException
	)
	
	begin {
		#region Utility Functions
		function Test-ActionParameter {
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $true)]
				[string]
				$Action,
				
				[Parameter(Mandatory = $true)]
				[System.Collections.Hashtable]
				$Parameters
			)
			
			$actionObject = $script:actions[$Action]
			$result = [pscustomobject]@{
				Success = $true
				MandatoryMissing = $actionObject.ParameterMandatory | Where-Object { $_ -notin $Parameters.Keys }
				UnknownParameters = $Parameters.Keys | Where-Object { $_ -notin $actionObject.ParameterMandatory -and $actionObject.ParameterOptional }
			}
			if ($result.MandatoryMissing -or $result.UnknownParameters) { $result.Success = $false }
			$result
		}
		#endregion Utility Functions
	}
	process {
		$parameterResult = Test-ActionParameter -Action $Action -Parameters $Parameters
		if (-not $parameterResult.Success) {
			Stop-PSFFunction -String 'Register-VMGuestConfiguration.BadParameters' -StringValues $Identity, $Action, ($parameterResult.MandatoryMissing -join ','), ($parameterResult.UnknownParameters -join ',') -EnableException $EnableException
			return
		}
		$script:configurations[$Identity] = [PSCustomObject]@{
			PSTypeName = 'VMDeploy.Guest.ConfigurationEntry'
			Identity   = $Identity
			Weight	   = $Weight
			Action	   = $Action
			Parameters = $Parameters
			DependsOn  = $DependsOn
			Source	   = $Source
		}
	}
}
