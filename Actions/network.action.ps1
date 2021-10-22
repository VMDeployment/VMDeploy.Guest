$executionCode = {
	param (
		$Configuration
	)

	$netConfigs = Get-NetIPConfiguration
	$netConfig = $netConfigs | Where-Object InterfaceAlias -EQ Ethernet | Select-Object -First 1
	if (-not $netConfig) { $netConfig = $netConfigs | Where-Object InterfaceAlias -NotLike 'Loopback Pseudo-Interface*' | Select-Object -First 1 }

	if ($Configuration.IPAddress -and $netConfig.IPv4Address.IPAddress -notcontains $Configuration.IPAddress) {
		foreach ($address in $netConfig.IPv4Address) { Remove-NetIPAddress -IPAddress $address -InterfaceIndex $netConfig.InterfaceIndex -Confirm:$false }
		$param = @{
			IPAddress      = $Configuration.IPAddress
			InterfaceIndex = $netConfig.InterfaceIndex
			AddressFamily  = 'IPv4'
			PrefixLength   = 24
			Confirm        = $false
		}
		if ($Configuration.PrefixLength) { $param.PrefixLength = $Configuration.PrefixLength }
		New-NetIPAddress @param
	}
	elseif ($Configuration.PrefixLength) {
		$ipAddress = $netConfig.IPv4Address[0]
		if ($Configuration.IPAddress) { $ipAddress = $netConfig.IPv4Address | Where-Object IPAddress -EQ $Configuration.IPAddress }
		if ($ipAddress.PrefixLength -ne $Configuration.PrefixLength) {
			Set-NetIPAddress -IPAddress $ipAddress -InterfaceIndex 5 -PrefixLength $Configuration.PrefixLength -Confirm:$false
		}
	}
	if ($Configuration.DefaultGateway) {
		if ($netConfig.IPv4DefaultGateway.NextHop -notcontains $Configuration.DefaultGateway) {
			if (-not $netConfig.IPv4DefaultGateway) {
				New-NetRoute -InterfaceIndex $netConfig.InterfaceIndex -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -NextHop $Configuration.DefaultGateway
			}
			else {
				Set-NetRoute -InterfaceIndex $netConfig.InterfaceIndex -DestinationPrefix '0.0.0.0/0' -NextHop $Configuration.DefaultGateway
			}
		}
	}
	if ($Configuration.DnsServer) {
		Set-DnsClientServerAddress -InterfaceIndex $netConfig.InterfaceIndex -ServerAddresses $Configuration.DnsServer
	}
}

$validationCode = {
	param (
		$Configuration
	)

	$netConfigs = Get-NetIPConfiguration
	$netConfig = $netConfigs | Where-Object InterfaceAlias -EQ Ethernet | Select-Object -First 1
	if (-not $netConfig) { $netConfig = $netConfigs | Where-Object InterfaceAlias -NotLike 'Loopback Pseudo-Interface*' | Select-Object -First 1 }

	if ($Configuration.IPAddress -and $netConfig.IPv4Address.IPAddress -notcontains $Configuration.IPAddress) {
		return $false
	}
	if ($Configuration.PrefixLength) {
		$ipAddress = $netConfig.IPv4Address[0]
		if ($Configuration.IPAddress) { $ipAddress = $netConfig.IPv4Address | Where-Object IPAddress -EQ $Configuration.IPAddress }
		if ($ipAddress.PrefixLength -ne $Configuration.PrefixLength) { return $false }
	}
	if ($Configuration.DefaultGateway) {
		if ($netConfig.IPv4DefaultGateway.NextHop -notcontains $Configuration.DefaultGateway) {
			return $false
		}
	}
	if ($Configuration.DnsServer) {
		$actualServers = $netConfig.DNSServer.Where{ $_.AddressFamily -eq 2 }.ServerAddresses
		foreach ($server in $Configuration.DnsServer) {
			if ($server -notin $actualServers) { return $false }
		}
		foreach ($server in $actualServers) {
			if ($server -notin $Configuration.DnsServer) { return $false }
		}
	}

	$true
}

$param = @{
	Name               = 'network'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Implement client network configuration'
	ParameterMandatory = @(
	)
	ParameterOptional  = @(
		'IPAddress'
		'DefaultGateway'
		'DnsServer'
		'SubnetMask'
	)
	Tag                = 'network'
}
Register-VMGuestAction @param