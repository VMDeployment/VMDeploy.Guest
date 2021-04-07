$validate = {
	param (
		$Parameters
	)
	
	$exists = Test-Path -LiteralPath $Parameters.Path -PathType Container
	if (-not $exists) { return $false }
	$item = Get-Item -LiteralPath $Parameters.Path
	$item.PSProvider.Name -eq 'FileSystem'
}

$scriptblock = {
	param (
		$Parameters
	)
	
	$exists = Test-Path -LiteralPath $Parameters.Path -PathType Container
	if ($exists) { return }
	$null = New-Item -Path $Parameters.Path -ItemType Directory
}

$paramRegisterVMGuestAction = @{
	Name			   = 'NewFolder'
	ParameterMandatory = 'Path'
	Validate		   = $validate
	ScriptBlock	       = $scriptblock
	Description	       = 'Ensures a specific folder exists'
	Tag			       = 'filesystem', 'folder'
}

Register-VMGuestAction @paramRegisterVMGuestAction