function Register-VMGuestAction {
<#
	.SYNOPSIS
		Register a new guest action.
	
	.DESCRIPTION
		Register a new guest action.
		Actions implement the logic available to guest configuration entries.
	
	.PARAMETER Name
		The name of the action to register.
		Action-Names must be unique, if you define an action that already exists, you will overwrite the previous implementation.
	
	.PARAMETER ScriptBlock
		Code that is executed to implement the action.
		Should generally not throw exceptions.
		Receives a single argument/parameter: A hashtable containing any parameters.
	
	.PARAMETER Validate
		Code that is executed to validate, whether the action has been executed.
		Should generally not throw exceptions.
		This scriptblock should ever only return a single boolean value, all other data will be ignored.
		Receives a single argument/parameter: A hashtable containing any parameters.
	
	.PARAMETER Description
		A description text, explaining how the action works.
		Use this as a summary, orientation help and manual for using the action.

	.PARAMETER PreDeploymentCode
		Scriptblock that is executed within the VMDeployment JEA endpoint before the Virtual Machine creation is triggered.
		This allows executing code in the context of the JEA gMSA and dynamically preparing resources to be included in the deployment.
	
	.PARAMETER ParameterMandatory
		List of parameters that MUST be specified when defining an action configuration.
	
	.PARAMETER ParameterOptional
		List of parameters that can be optionally added when defining an action configuration.
	
	.PARAMETER Tag
		Any tags to add to an action.
		Tags are fully optional and are only used for keeping track of actions when defining too many.
	
	.EXAMPLE
		PS C:\> Register-VMGuestAction -Name 'NewFolder' -ScriptBlock $ScriptBlock -Validate $Validate -Description 'Creates a new folder' -ParameterMandatory Path
	
		Register a new action named "NewFolder", providing execution logic, validation logic and a speaking description.
		Configuration entries using it must specify a Path parameter.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$Validate,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$PreDeploymentCode,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ParameterMandatory = @(),
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ParameterOptional = @(),
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Tag
	)
	
	process {
		$script:actions[$Name] = [pscustomobject]@{
			PSTypeName		   = 'VMDeploy.Guest.Action'
			Name			   = $Name
			ScriptBlock	       = $ScriptBlock
			Validate		   = $Validate
			Description	       = $Description
			PreDeploymentCode  = $PreDeploymentCode
			ParameterMandatory = $ParameterMandatory
			ParameterOptional  = $ParameterOptional
			Tag			       = $Tag
		}
	}
}