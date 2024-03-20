$executionCode = {
	param (
		$Configuration
	)

	$param = @{
		FilePath          = "VMDeploy:\Resources\__cert_$($Configuration.Name).pfx"
		CertStoreLocation = 'Cert:\LocalMachine\My'
		Password          = ("DoesNotMatter" | ConvertTo-SecureString -AsPlainText -Force)
	}
	Import-PfxCertificate @param

	$certPath = (Get-Item -Path "VMDeploy:\Resources\__cert_$($Configuration.Name).pfx").FullName
	$certObject = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certPath, "DoesNotMatter")

	switch ($Configuration.CertRoles) {
		'RDP' {
			$instance = Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TSGeneralSetting -Filter 'TerminalName = "RDP-TCP"'
			$instance | Set-CimInstance -Property @{ SSLCertificateSHA1Hash = $certObject.Thumbprint } -ErrorAction Stop
		}
	}
}

$validationCode = {
	param (
		$Configuration
	)

	if (-not (Test-Path "VMDeploy:\Resources\__cert_$($Configuration.Name).pfx")) { return $false }
	$certPath = (Get-Item -Path "VMDeploy:\Resources\__cert_$($Configuration.Name).pfx").FullName
	$certObject = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certPath, "DoesNotMatter")

	if (-not (Test-Path -Path "Cert:\LocalMachine\My\$($certObject.Thumbprint)")) {
		return $false
	}

	switch ($Configuration.CertRoles) {
		'RDP' {
			$instance = Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TSGeneralSetting -Filter 'TerminalName = "RDP-TCP"'
			if ($instance.SSLCertificateSHA1Hash -ne $certObject.Thumbprint) { return $false }
		}
	}

	$true
}

$PreDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)
	# Explicitly import module since auto-import does not happen on JEA endpoints
	Import-Module PKI

	# Process FQDN
	$fqdn = $Configuration.Fqdn
	if (-not $fqdn) { $fqdn = Read-Host "Enter FQDN of target computer for certificate request" }

	#region Functions
	function New-CertificateRequest {
		[OutputType([string])]
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]
			$Template,

			[Parameter(Mandatory = $true)]
			[string]
			$Fqdn,

			[Parameter(Mandatory = $true)]
			[string]
			$WorkingDirectory
		)

		$templateData = @"
[Version]
Signature="`$Windows NT$"
[NewRequest]
Subject = "CN=$Fqdn"
Exportable = True
KeyLength = 2048
KeySpec = 1
KeyUsage = 0xA0
MachineKeySet = True
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
RequestType = PKCS10
SMIME = FALSE
[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=$Fqdn"
[RequestAttributes]
CertificateTemplate = "$Template"
"@
		Remove-Item "$WorkingDirectory\_certReq.req" -ErrorAction Ignore
		[System.IO.File]::WriteAllText("$WorkingDirectory\_certReq.inf", $templateData, [System.Text.Encoding]::ASCII)
		$result = CertReq.exe -new -q "$WorkingDirectory\_certReq.inf" "$WorkingDirectory\_certReq.req"
		if ($LASTEXITCODE -ne 0) {
			Remove-Item "$WorkingDirectory\_certReq.inf" -ErrorAction Ignore
			foreach ($line in $result) {
				Write-Warning $line
			}
			throw "Failed to create certificate request!"
		}

		Remove-Item "$WorkingDirectory\_certReq.inf" -ErrorAction Ignore
		"$WorkingDirectory\_certReq.req"
	}
	
	function Send-CertificateRequest {
		#[OutputType([int])]
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]
			$RequestPath,

			[Parameter(Mandatory = $true)]
			[string]
			$CA
		)

		$certPath = $RequestPath -replace '\.req$', '.cer'
		$responsePath = $RequestPath -replace '\.req$', '.rsp'
		Remove-Item $certPath -ErrorAction Ignore
		Remove-Item $responsePath -ErrorAction Ignore
		$result = CertReq.exe -submit -kerberos -q -config $CA $RequestPath $certPath
		if ($LASTEXITCODE -ne 0) {
			Remove-Item $RequestPath -ErrorAction Ignore
			Remove-Item $responsePath -ErrorAction Ignore
			foreach ($line in $result) {
				Write-Warning $line
			}
			throw "Failed to submit certificate request!"
		}
		Remove-Item $RequestPath -ErrorAction Ignore
		Remove-Item $responsePath -ErrorAction Ignore

		[PSCustomObject]@{
			Path      = $certPath
			RequestID = ($result | Where-Object { $_ -match '^RequestID: \d+$' }) -replace '^RequestID: (\d+)$', '$1' -as [int]
			Result    = $result
		}
	}

	function Test-CertificateRequest {
		[CmdletBinding()]
		param (
			[string]
			$CA,

			[int]
			$RequestID,

			[string]
			$CertPath
		)

		Remove-Item -Path ($CertPath -replace '\.cer$', '.rsp') -ErrorAction Ignore
		$result = CertReq.exe -retrieve -kerberos -q -config $CA $RequestID $CertPath
		if ($LASTEXITCODE -ne 0) {
			foreach ($line in $result) {
				Write-Warning $line
			}
			throw "Failed to retrieve certificate request!"
		}
		Test-Path $CertPath
	}

	function Receive-Certificate {
		[CmdletBinding()]
		param (
			[string]
			$CA,

			[int]
			$RequestID,

			[string]
			$CertPath
		)

		if (Test-Path $CertPath) {
			Remove-Item -Path ($CertPath -replace '\.cer$', '.rsp') -ErrorAction Ignore
			$result = certreq -accept -q $CertPath
			if ($LASTEXITCODE -ne 0) {
				foreach ($line in $result) {
					Write-Warning $line
				}
				Remove-Item -Path $CertPath -ErrorAction Ignore
				throw "Failed to accept certificate!"
			}

			$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertPath)
			$certificate.Thumbprint
			$certificate.Dispose()
			Remove-Item -Path $CertPath -ErrorAction Ignore
			return
		}

		Write-Host "Waiting for Certificate Request $($RequestID) from $($CA) being approved"
		while (-not (Test-CertificateRequest -RequestID $RequestID -CA $CA -CertPath $CertPath)) {
			Start-Sleep -Seconds 1
		}
		Write-Host "Request approved, certificate received"
		Remove-Item -Path ($CertPath -replace '\.cer$', '.rsp') -ErrorAction Ignore
		$result = certreq -accept -q $CertPath
		if ($LASTEXITCODE -ne 0) {
			foreach ($line in $result) {
				Write-Warning $line
			}
			Remove-Item -Path $CertPath -ErrorAction Ignore
			throw "Failed to accept certificate!"
		}
		$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertPath)
		$certificate.Thumbprint
		$certificate.Dispose()
		Remove-Item -Path $CertPath -ErrorAction Ignore
	}
	#endregion Functions

	$requestPath = New-CertificateRequest -Template $Configuration.Template -Fqdn $fqdn -WorkingDirectory $WorkingDirectory
	$request = Send-CertificateRequest -RequestPath $requestPath -CA $Configuration.CA
	$thumbprint = Receive-Certificate -CA $Configuration.CA -RequestID $request.RequestID -CertPath $request.Path
	$null = Get-Item "Cert:\LocalMachine\My\$thumbprint" | Export-PfxCertificate -FilePath "$WorkingDirectory\Resources\__cert_$($Configuration.Name).pfx" -Password ("DoesNotMatter" | ConvertTo-SecureString -AsPlainText -Force)
	Remove-Item "Cert:\LocalMachine\My\$thumbprint"
}

$param = @{
	Name               = 'certificate'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Request and apply a certificate to the deployed virtual machine'
	PreDeploymentCode  = $PreDeploymentCode
	ParameterMandatory = @(
		'CA' # FQCA - 'vmdf1dc.contoso.com\contoso-VMDF1DC-CA'
		'Template' # System Name, not Displayname
		'Name' # Name of the cert file, in case multiple cert definitions concur
	)
	ParameterOptional  = @(
		'Fqdn' # Prompted if not configured
		'CertRoles' # Determines other execution logic to apply to the certificate after installation.
					# Supported Roles: RDP
	)
	Tag                = 'certificate', 'pki'
}
Register-VMGuestAction @param