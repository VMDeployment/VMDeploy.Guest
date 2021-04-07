function Register-VMGuestAction {
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
			ParameterMandatory = $ParameterMandatory
			ParameterOptional  = $ParameterOptional
			Tag			       = $Tag
		}
	}
}