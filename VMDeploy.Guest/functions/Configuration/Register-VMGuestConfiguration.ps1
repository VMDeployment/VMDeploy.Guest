function Register-VMGuestConfiguration
{
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
		$Source = '<unknown>'
	)
	
	process
	{
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
