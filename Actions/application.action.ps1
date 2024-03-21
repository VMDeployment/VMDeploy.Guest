$executionCode = {
	param (
		$Configuration
	)

	$param = @{
		Path = $Configuration.Path
		Wait = $true
		PassThru = $true
	}
	if ($Configuration.Arguments) { $param.ArgumentList = $Configuration.Arguments }

	$result = Start-Process @param
	if ($result.ExitCode -eq 0) {
		$trackingFile = Join-Path -Path 'VMDeploy:\Runtime' -ChildPath $Configuration.Name
		"Success" | Set-Content -Path $trackingFile
		return
	}

	Write-PSFMessage -Level Warning -Message "Application '{0}' failed with exit code {1}" -StringValues $Configuration.Path, $result.ExitCode -ModuleName 'VMDeploy.Guest' -Data @{
		Path = $Configuration.Path
		Arguments = $Configuration.Arguments -join " "
		ExitCode = $result.ExitCode
	}
}

$validationCode = {
	param (
		$Configuration
	)

	if (-not (Test-Path 'VMDeploy:\Runtime')) {
		$null = New-Item -Path 'VMDeploy:\Runtime' -ItemType Directory -Force
	}

	$trackingFile = Join-Path -Path 'VMDeploy:\Runtime' -ChildPath $Configuration.Name
	Test-Path $trackingFile
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'application'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Execute an application'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'Name'
		'Path'
	)
	ParameterOptional = @(
		'Arguments'
	)
	Tag                = 'application','generic'
}
Register-VMGuestAction @param