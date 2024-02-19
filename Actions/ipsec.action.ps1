$executionCode = {
	param (
		$Configuration
	)

	#region Functions
	function Set-IPSecRule {   
		<#
			.SYNOPSIS
				Set IPSecRule to communicate between different network zones.
			
			.DESCRIPTION
				Set IPSecRule to communicate between different network zones.
			
			.PARAMETER Displayname
				Name of the IPSec rule
			
			.PARAMETER Authority
				CA path
			
			.PARAMETER RemoteAddress
				Remote address from the Endpoint 2 (subnet or specific IP address).
			
			.EXAMPLE
				
		#>
		
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]
			$DisplayName,
	
			[Parameter(Mandatory = $true)]
			[string]
			$Authority,
		
			[Parameter(Mandatory = $false)]
			$RemoteAddress = "Any",
	
			[Parameter(Mandatory = $false)]
			$LocalAddress = "Any",
	
			[Parameter(Mandatory = $false)]
			$Protocol = "Any",
			
			[Parameter(Mandatory = $false)]
			$RemotePort = "Any",
	
			[Parameter(Mandatory = $false)]
			$LocalPort = "Any",
	
			[Parameter(Mandatory = $false)]
			$Enabled = "True",
	
			[Parameter(Mandatory = $false)]
			[string]
			$Security = "Require"
	
		)
	
		begin {
			# Remove local IP Address from remote addresses (if any)
			# Including a local IP Address on a remote address for IPSec Rules is going to break networking
			$localIPAddresses = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces().GetIPProperties().UnicastAddresses.ForEach{$_.Address}.IPAddressToString
			$actualRemoteAddresses = $RemoteAddress | Where-Object { $_ -notin $localIPAddresses }
			if (-not $actualRemoteAddresses) {
				Write-PSFMessage -Level Warning -Message "No valid remote addresses remaining: $($RemoteAddress -join ',') were only local addresses!" -Data @{
					Remote = $RemoteAddress -join ','
					LocalIP = $localIPAddresses -join ','
				}
				throw "No valid remote addresses remaining: $($RemoteAddress -join ',') were only local addresses!"
			}
		}
		process {
			$certProposal = New-NetIPsecAuthProposal -Machine -Cert -Authority $Authority -AuthorityType "root" -Signing RSA -ErrorAction SilentlyContinue
			$certAuthSet = New-NetIPsecPhase1AuthSet -PolicyStore 'localhost' -DisplayName $DisplayName -Proposal $certProposal -ErrorAction Stop
			New-NetIPsecRule -PolicyStore 'localhost' -DisplayName $DisplayName -Name $DisplayName -InboundSecurity $Security -OutboundSecurity $Security -Phase1AuthSet $certAuthSet.Name -Mode Transport -LocalAddress $LocalAddress -RemoteAddress $actualRemoteAddresses -Phase2AuthSet None -Protocol $Protocol -RemotePort $RemotePort -LocalPort $LocalPort -Enabled $Enabled 
		}
	}
	#endregion Functions

	Set-IPSecRule @Configuration
}

$validationCode = {
	param (
		$Configuration
	)

	$rule = Get-NetIPSecRule -DisplayName $Configuration.DisplayName -PolicyStore localhost -ErrorAction Ignore
	if (-not $rule) { return $false }

	$true
}

$param = @{
	Name               = 'ipsec'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Create IPSec Rules'
	ParameterMandatory = @(
		'DisplayName'
		'Authority'
	)
	ParameterOptional = @(
		'RemoteAddress'
		'LocalAddress'
		'Protocol'
		'RemotePort'
		'LocalPort'
		'Enabled'
		'Security'
	)
	Tag                = 'Network', 'ipsec'
}
Register-VMGuestAction @param