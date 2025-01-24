$executionCode = {
	param (
		$Configuration
	)

	Install-WindowsFeature -Name $Configuration.Name -IncludeAllSubFeature:($Configuration.AllSubFeatures -as [bool]) -IncludeManagementTools:(-not $Configuration.ExcludeTools)
}

$validationCode = {
	param (
		$Configuration
	)

	(Get-WindowsFeature -Name $Configuration.Name).Installed -as [bool]
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'serverfeature'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Enables a server feature'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'Name'
	)
	ParameterOptional = @(
		'AllSubFeatures'
		'ExcludeTools'
	)
	Tag                = 'windows','role'
}
Register-VMGuestAction @param