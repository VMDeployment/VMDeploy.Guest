$executionCode = {
	param (
		$Configuration
	)

	if (Test-Path "$env:WinDir\System32\GroupPolicyUsers") {
		Remove-Item "$env:WinDir\System32\GroupPolicyUsers\*" -Recurse -Force -ErrorAction Stop
	}
	if (Test-Path "$env:WinDir\System32\GroupPolicy") {
		Remove-Item "$env:WinDir\System32\GroupPolicy\*" -Recurse -Force -ErrorAction Stop
	}

	secedit /configure /cfg $env:WinDir\inf\defltbase.inf /db defltbase.sdb /verbose

	if (Get-NetIPsecMainModeCryptoSet -PolicyStore 'localhost') {
		Get-NetIPsecMainModeCryptoSet -PolicyStore 'localhost' | Remove-NetIPsecMainModeCryptoSet -ErrorAction Stop
	}

	if (Get-NetIPsecRule -PolicyStore 'localhost') {
		Get-NetIPsecRule -PolicyStore 'localhost' | Remove-NetIPsecRule -ErrorAction Stop
	}
	if (Get-NetIPsecPhase1AuthSet -PolicyStore 'localhost') {
		Get-NetIPsecPhase1AuthSet -PolicyStore 'localhost' | Remove-NetIPsecPhase1AuthSet -ErrorAction Stop
	}
	if (Get-NetIPsecRule -PolicyStore PersistentStore) {
		Get-NetIPsecRule -PolicyStore PersistentStore | Remove-NetIPsecRule -ErrorAction Stop
	}
	if (Get-NetIPsecPhase1AuthSet -PolicyStore PersistentStore) {
		Get-NetIPsecPhase1AuthSet -PolicyStore PersistentStore | Remove-NetIPsecPhase1AuthSet -ErrorAction Stop
	}
}

$validationCode = {
	param (
		$Configuration
	)

	$allIsWell = $true
	$msgCommon = @{
		FunctionName = 'policy_clear'
		ModuleName = 'VMDeploy.Guest'
	}

	if (Get-Item "$env:WinDir\System32\GroupPolicyUsers\*" -Force -ErrorAction Ignore) {
		$allIsWell = $false
		Write-PSFMessage -Message 'Local User Policies found' @msgCommon
	}

	if (Get-NetIPsecMainModeCryptoSet -PolicyStore 'localhost') {
		$allIsWell = $false
		Write-PSFMessage -Message 'IPSec Main Mode CryptoSet found' @msgCommon
	}

	if (Get-NetIPsecRule -PolicyStore 'localhost') {
		$allIsWell = $false
		Write-PSFMessage -Message 'IPSec rules found in the local store' @msgCommon
	}
	if (Get-NetIPsecPhase1AuthSet -PolicyStore 'localhost') {
		$allIsWell = $false
		Write-PSFMessage -Message 'IPSec Phase 1 AuthSet found in the local store' @msgCommon
	}
	if (Get-NetIPsecRule -PolicyStore PersistentStore) {
		$allIsWell = $false
		Write-PSFMessage -Message 'IPSec rules found in the persistent store' @msgCommon
	}
	if (Get-NetIPsecPhase1AuthSet -PolicyStore PersistentStore) {
		$allIsWell = $false
		Write-PSFMessage -Message 'IPSec Phase 1 AuthSet found in the persistent store' @msgCommon
	}

	$allIsWell
}

$param = @{
	Name               = 'policy_clear'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Resets the local policy & security configuration.'
	ParameterMandatory = @(
		
	)
	ParameterOptional  = @(
	)
	Tag                = 'policy', 'ipsec', 'remove', 'clear'
}
Register-VMGuestAction @param