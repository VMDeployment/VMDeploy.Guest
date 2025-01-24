$executionCode = {
	param (
		$Configuration
	)

	Set-NetFirewallSetting -PolicyStore Localhost -Exemptions $Configuration.Exemptions -ErrorAction Stop
}

$validationCode = {
	param (
		$Configuration
	)

	$fwConfig = Get-NetFirewallSetting -PolicyStore Localhost
	$Configuration.Exemptions -eq $fwConfig.Exemptions
}

$param = @{
	Name               = 'firewall_exemptions'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Manage global firewall exemption settings for the local store'
	ParameterMandatory = @(
		'Exemptions'
	)
	ParameterOptional  = @(
	)
	Tag                = 'firewall', 'config'
}
Register-VMGuestAction @param