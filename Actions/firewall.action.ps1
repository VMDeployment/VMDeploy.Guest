$executionCode = {
	param (
		$Configuration
	)

	$properties = 'Exemptions','EnableStatefulFtp','EnableStatefulPptp','ActiveProfile','RemoteMachineTransportAuthorizationList','RemoteMachineTunnelAuthorizationList','RemoteUserTransportAuthorizationList','RemoteUserTunnelAuthorizationList','RequireFullAuthSupport','CertValidationLevel','AllowIPsecThroughNAT','MaxSAIdleTimeSeconds','KeyEncoding','EnablePacketQueuing'
	$fwConfig = Get-NetFirewallSetting
	$param = @{ PolicyStore = 'Localhost' }

	foreach ($property in $properties) {
		if ($Configuration.Keys -notcontains $property) { continue }
		if ($Configuration.$property -eq $fwConfig.$property) { continue }
		$param.$property = $Configuration.$property
	}

	Set-NetFirewallSetting @param -ErrorAction Stop
}

$validationCode = {
	param (
		$Configuration
	)

	$properties = 'Exemptions','EnableStatefulFtp','EnableStatefulPptp','ActiveProfile','RemoteMachineTransportAuthorizationList','RemoteMachineTunnelAuthorizationList','RemoteUserTransportAuthorizationList','RemoteUserTunnelAuthorizationList','RequireFullAuthSupport','CertValidationLevel','AllowIPsecThroughNAT','MaxSAIdleTimeSeconds','KeyEncoding','EnablePacketQueuing'
	$fwConfig = Get-NetFirewallSetting

	foreach ($property in $properties) {
		if ($Configuration.Keys -notcontains $property) { continue }
		if ($Configuration.$property -eq $fwConfig.$property) { continue }
		return $false
	}
	$true
}

$param = @{
	Name               = 'firewall'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Manage global firewall settings for the local store'
	ParameterMandatory = @(
		
	)
	ParameterOptional  = @(
		'Exemptions'
		'EnableStatefulFtp'
		'EnableStatefulPptp'
		'ActiveProfile'
		'RemoteMachineTransportAuthorizationList'
		'RemoteMachineTunnelAuthorizationList'
		'RemoteUserTransportAuthorizationList'
		'RemoteUserTunnelAuthorizationList'
		'RequireFullAuthSupport'
		'CertValidationLevel'
		'AllowIPsecThroughNAT'
		'MaxSAIdleTimeSeconds'
		'KeyEncoding'
		'EnablePacketQueuing'
	)
	Tag                = 'firewall', 'config'
}
Register-VMGuestAction @param