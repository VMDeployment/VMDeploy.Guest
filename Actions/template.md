# Template

```powershell
$executionCode = {
	param (
		$Configuration
	)
}

$validationCode = {
	param (
		$Configuration
	)

	$true
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)

	Write-Host "Predeployment Test: $($Configuration.Whatever) - $WorkingDirectory"
}

$param = @{
	Name               = 'dummy'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Do Nothing'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'Whatever'
	)
	ParameterOptional = @(
	)
	Tag                = 'dummy'
}
Register-VMGuestAction @param
```
