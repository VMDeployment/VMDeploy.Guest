$executionCode = {
	param (
		$Configuration
	)

	$driveLetter = (Get-Item -Path VMDeploy:\).FullName -replace ':.+'
	Get-Volume -DriveLetter $driveLetter | Get-Partition | Get-Disk | Set-Disk -IsReadOnly $false

	$logPath = 'VMDeploy:\logs'
	if (-not (Test-Path -Path $logPath)) {
		$null = New-Item -Path $logPath -ItemType Directory -Force -ErrorAction Stop
	}
	$resolvedPath = (Get-Item -Path $logPath -ErrorAction Stop).FullName

	Set-PSFLoggingProvider -Name logfile -InstanceName VMDeployDebugLog -FilePath "$env:Temp\vmdeploy_debug_$(Get-Date -Format yyyy-MM-dd_HH-mm-ss).csv" -Enabled $true -Wait -CopyOnFinal $resolvedPath
}

$validationCode = {
	param (
		$Configuration
	)

	(Get-PSFLoggingProviderInstance -ProviderName logfile -Name VMDeployDebugLog | Where-Object Enabled) -as [bool]
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'debug'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Enables the Debug Log to the deployment disk'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
	)
	ParameterOptional  = @(
	)
	Tag                = 'debug'
}
Register-VMGuestAction @param