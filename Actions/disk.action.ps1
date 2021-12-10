$executionCode = {
	param (
		$Configuration
	)

	$disk = Get-Disk | Where-Object Location -Match "LUN $($Configuration.Lun)$"
	if (-not $disk) {
		Write-PSFMessage -Level Warning -Message 'Error configuring volume {1} (LUN ID {0}): Disk not found, validate VM deployment!' -StringValues $Configuration.Lun, $Configuration.Letter -Data $Configuration -Target $Configuration.Letter -ModuleName 'VMDeploy.Guest'
		return
	}

	if ($disk.IsOffline) {
		$disk | Set-Disk -IsOffline $false
		Start-Sleep -Seconds 1
	}

	$volume = $disk | Get-Partition | Get-Volume
	if (-not $volume) {
		$disk | Initialize-Disk -ErrorAction Ignore
		$partition = $disk | New-Partition -UseMaximumSize
		$volume = $partition | Get-Volume | Format-Volume -FileSystem NTFS
	}
	$letterOccupyingVolume = Get-Volume -DriveLetter $Configuration.Letter -ErrorAction Ignore
	if ($letterOccupyingVolume -and $letterOccupyingVolume.UniqueId -ne $volume.UniqueId) {
		$null = "SELECT VOLUME $($Configuration.Letter)", "REMOVE LETTER $($Configuration.Letter)" | diskpart
	}
	if ($volume.DriveLetter -ne $Configuration.Letter) {
		$volume | Get-Partition | Set-Partition -NewDriveLetter $Configuration.Letter -ErrorAction Stop
	}

	if ($Configuration.Label -and $Configuration.Label -ne $volume.FileSystemLabel) {
		$volume | Set-Volume -NewFileSystemLabel $Configuration.Label -ErrorAction Stop
	}
}

$validationCode = {
	param (
		$Configuration
	)

	$disk = Get-Disk | Where-Object Location -Match "LUN $($Configuration.Lun)$"
	if (-not $disk) {
		Write-PSFMessage -Level Warning -Message 'Error configuring volume {1} (LUN ID {0}): Disk not found, validate VM deployment!' -StringValues $Configuration.Lun, $Configuration.Letter -Data $Configuration -Target $Configuration.Letter -ModuleName 'VMDeploy.Guest'
		return $false
	}

	if ($disk.IsOffline) { return $false }

	$volume = $disk | Get-Partition | Get-Volume | Where-Object DriveLetter -EQ $Configuration.Letter
	if (-not $volume) { return $false }
	if ($Configuration.Label -and $Configuration.Label -ne $volume.FileSystemLabel) {
		return $false
	}
	$true
}

$param = @{
	Name               = 'disk'
	ScriptBlock        = $executionCode
	Validate           = $validationCode
	Description        = 'Configure a disk'
	ParameterMandatory = @(
		'Lun'
		'Letter'
	)
	ParameterOptional = @(
		'Label'
		'Size'
	)
	Tag                = 'volume', 'disk'
}
Register-VMGuestAction @param