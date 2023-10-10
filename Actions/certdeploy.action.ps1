$executionCode = {
	param (
		$Configuration
	)

	$filePath = Join-Path -Path 'VMDeploy:\Resources' -ChildPath $Configuration.FileName
	if (-not (Test-Path -Path $filePath)) {
		Write-PSFMessage -Level Warning -Message "Certificate file not found in the VMDeploy package! Ensure the $($Configuration.FileName) certificate is deployed as a resource!"
		return
	}
	$fullFilePath = (Get-Item -Path $filePath).FullName
	try { $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($fullFilePath) }
	catch {
		Write-PSFMessage -Level Warning -Message "Error opening certificate $($Configuration.FileName)" -ErrorRecord $_
		return
	}

	try {
		$store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
			$Configuration.Store,
			[System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
		)
		$store.Open('ReadWrite')
	}
	catch {
		Write-PSFMessage -Level Warning -Message "Error accessing certificate store $($Configuration.Store)" -ErrorRecord $_
		return
	}

	try { $store.Add($certificate) }
	catch {
		Write-PSFMessage -Level Warning -Message "Error writing certificate $($Configuration.FileName) to certificate store $($Configuration.Store)" -ErrorRecord $_
		return
	}
}

$validationCode = {
	param (
		$Configuration
	)

	$filePath = Join-Path -Path 'VMDeploy:\Resources' -ChildPath $Configuration.FileName
	if (-not (Test-Path -Path $filePath)) {
		Write-PSFMessage -Level Warning -Message "Certificate file not found in the VMDeploy package! Ensure the $($Configuration.FileName) certificate is deployed as a resource!"
		return $false
	}
	$fullFilePath = (Get-Item -Path $filePath).FullName
	try { $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($fullFilePath) }
	catch {
		Write-PSFMessage -Level Warning -Message "Error opening certificate $($Configuration.FileName)" -ErrorRecord $_
		return $false
	}

	try {
		$store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
			$Configuration.Store,
			[System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
		)
		$store.Open('ReadOnly')
	}
	catch {
		Write-PSFMessage -Level Warning -Message "Error accessing certificate store $($Configuration.Store)" -ErrorRecord $_
		return $false
	}
	$store.Certificates.ThumbPrint -contains $certificate.ThumbPrint
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
}

$param = @{
	Name               = 'CertDeploy'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Deploys a certificate to the specified certificate store'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'FileName'
		'Store'
	)
	ParameterOptional = @(
	)
	Tag                = 'certificate', 'pki'
}
Register-VMGuestAction @param