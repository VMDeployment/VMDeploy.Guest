$executionCode = {
	param (
		$Configuration
	)

	Rename-Computer -NewName $Configuration.Name -ErrorAction Stop -WarningAction SilentlyContinue -Force -Confirm:$false
}

$validationCode = {
	param (
		$Configuration
	)

	$env:COMPUTERNAME -eq $Configuration.Name
}

$param = @{
	Name               = 'Computername'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Assigns the name to the computer. This action is auto-configured and needs/should not be defined explicitly'
	ParameterMandatory = @(
		'Name'
	)
	ParameterOptional = @(
	)
	Tag                = 'Computername'
}
Register-VMGuestAction @param