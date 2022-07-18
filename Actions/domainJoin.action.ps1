$executionCode = {
	param (
		$Configuration
	)

	$data = Import-PSFCLixml -Path 'VMDeploy:\Resources\__joindomain.dat'
	$param = @{
		ComputerName = $env:COMPUTERNAME
		DomainName = $data.Domain
		Credential = [PSCredential]::new("$($data.Domain)\$($data.AccountName)", ($data.Password | ConvertTo-SecureString -AsPlainText -Force))
	}
	if ($Configuration.OU) {
		$param.OUPath = $Configuration.OU
	}
	if (Test-Path -Path 'VMDeploy:\Resources\__computername.dat') {
		$param.ComputerName = Import-PSFCLixml -Path 'VMDeploy:\Resources\__computername.dat'
	}
	Add-Computer @param -ErrorAction stop
}

$validationCode = {
	param (
		$Configuration
	)

	$data = Import-PSFCLixml -Path 'VMDeploy:\Resources\__joindomain.dat'
	(Get-CimInstance win32_computersystem).Domain -eq $data.Domain
}

$preDeploymentCode = {
	param (
		$Configuration,

		$WorkingDirectory
	)

	$data = @{ }
	if ($Configuration.Domain) { $data.Domain = $Configuration.Domain }
	else { $data.Domain = Read-Host "Enter FQDN of Domain to join the VM to" }
	if ($Configuration.AccountName) { $data.AccountName = $Configuration.AccountName }
	else { $data.AccountName = Read-Host "Enter Name of Account to use for joining the VM to the target domain" }
	if ($Configuration.Password) { $data.Password = $Configuration.Password }
	else {
		$password = Read-Host "Enter Password used to join VM to domain" -AsSecureString
		$data.Password = [PSCredential]::New("whatever", $password).GetNetworkCredential().Password
	}

	$data | Export-PSFClixml -Path "$WorkingDirectory\Resources\__joindomain.dat"
}

$param = @{
	Name               = 'domainJoin'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	PreDeploymentCode  = $preDeploymentCode
	Description        = 'Join Computer to a Target Domain'
	ParameterMandatory = @(
		
	)
	ParameterOptional = @(
		'Domain'
		'AccountName'
		'Password'
		'OU'
	)
	Tag                = 'ad', 'join'
}
Register-VMGuestAction @param