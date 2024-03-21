$executionCode = {
	param (
		$Configuration
	)

	try { Disable-PSFLoggingProvider -Name logfile -InstanceName VMDeployDebugLog }
	catch { }

	Wait-PSFMessage
}

$validationCode = {
	param (
		$Configuration
	)

	-not (Get-PSFLoggingProviderInstance -ProviderName logfile -Name VMDeployDebugLog | Where-Object Enabled)
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'debug_end'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Closes the debug log. Should be the last config to run and not persist its success'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
	)
	ParameterOptional  = @(
	)
	Tag                = 'debug'
}
Register-VMGuestAction @param