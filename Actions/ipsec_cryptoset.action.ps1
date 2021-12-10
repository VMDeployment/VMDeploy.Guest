$executionCode = {
	param (
		$Configuration
	)

	$cryptoSet = Get-NetIPsecMainModeCryptoSet -PolicyStore localhost -DisplayName $Configuration.DisplayName -ErrorAction Ignore
	if ($cryptoSet) { $cryptoSet | Remove-NetIPsecMainModeCryptoSet }

	$paramProp = @{
		# Default Values
		Encryption  = 'AES256'
		Hash        = 'SHA256'
		KeyExchange = 'DH20'
	}
	if ($Configuration.Encryption) { $paramProp.Encryption = $Configuration.Encryption }
	if ($Configuration.Hash) { $paramProp.Hash = $Configuration.Hash }
	if ($Configuration.KeyExchange) { $paramProp.KeyExchange = $Configuration.KeyExchange }
	$cryptosetProposal = New-NetIPsecMainModeCryptoProposal @paramProp

	$paramCrypto = @{
		PolicyStore = 'localhost'
		Proposal    = $cryptosetProposal
		DisplayName = $Configuration.DisplayName
	}
	if ($Configuration.Default) { $paramCrypto.Default = $Configuration.Default }

	$null = New-NetIPsecMainModeCryptoSet @paramCrypto
}

$validationCode = {
	param (
		$Configuration
	)

	$cryptoSet = Get-NetIPsecMainModeCryptoSet -PolicyStore localhost -DisplayName $Configuration.DisplayName -ErrorAction Ignore
	if (-not $cryptoSet) { return $false }

	if ($cryptoSet.Proposal.Count -ne 1) { return $false }

	$intended = @{
		# Default Values
		Encryption  = 'AES256'
		Hash        = 'SHA256'
		KeyExchange = 'DH20'
	}
	if ($Configuration.Encryption) { $intended.Encryption = $Configuration.Encryption }
	if ($Configuration.Hash) { $intended.Hash = $Configuration.Hash }
	if ($Configuration.KeyExchange) { $intended.KeyExchange = $Configuration.KeyExchange }

	if ($cryptoSet.Proposal[0].Encryption -ne $intended.Encryption) { return $false }
	if ($cryptoSet.Proposal[0].Hash -ne $intended.Hash) { return $false }
	if ($cryptoSet.Proposal[0].KeyExchange -ne $intended.KeyExchange) { return $false }

	$true
}

$param = @{
	Name               = 'ipsec_cryptoset'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Define an IPSec Crypto Set'
	ParameterMandatory = @(
		'DisplayName'
	)
	ParameterOptional  = @(
		'Encryption'
		'Hash'
		'KeyExchange'
		'Default'
	)
	Tag                = 'ipsec', 'crypto'
}
Register-VMGuestAction @param