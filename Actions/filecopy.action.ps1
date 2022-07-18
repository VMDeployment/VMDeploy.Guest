$executionCode = {
	param (
		$Configuration
	)

	foreach ($item in $Configuration.Path) {
		$targetPath = Join-Path -Path $Configuration.Destination -ChildPath $item
		if (Test-Path -Path $targetPath) { continue }

		$sourcePath = Join-Path -Path 'VMDeploy:\Resources' -ChildPath $item
		Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
	}
}

$validationCode = {
	param (
		$Configuration
	)

	foreach ($item in $Configuration.Path) {
		$targetPath = Join-Path -Path $Configuration.Destination -ChildPath $item
		if (-not (Test-Path -Path $targetPath)) { return $false }
	}

	$true
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'filecopy'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Copies files from resources to the target path within the guest OS'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'Path' # Source path(s) within the resources folder - e.g. SCCM_Setup | Use the exact same notation as in the Resources config
		'Destination' # Target folder on os - e.g.: C:\contoso\scripts
	)
	ParameterOptional = @(
	)
	Tag                = 'dummy'
}
Register-VMGuestAction @param