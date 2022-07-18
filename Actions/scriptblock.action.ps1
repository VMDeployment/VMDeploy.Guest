$executionCode = {
	param (
		$Configuration
	)

	$global:_____ScriptBlockSuccess = $false
	try {
		& $Configuration.ScriptBlock $Configuration.Parameters
		$global:_____ScriptBlockSuccess = $true
	}
	catch {
		Write-PSFMessage -Level Error -Message "Failed" -ErrorRecord $_
		throw
	}
}

$validationCode = {
	param (
		$Configuration
	)

	$global:_____ScriptBlockSuccess
}

$param = @{
	Name               = 'Scriptblock'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Executes a ScriptBlock'
	ParameterMandatory = @(
		'ScriptBlock'
	)
	ParameterOptional = @(
		'Parameters'
	)
	Tag                = 'code'
}
Register-VMGuestAction @param