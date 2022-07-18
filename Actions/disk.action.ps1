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

	#region BitLocker
	$protectionMode = 'Ignore'
	if ($Configuration.BitLocker) { $protectionMode = $Configuration.BitLocker }
	if ('Ignore' -eq $protectionMode) { return $true }

	if ($invalidOptions = $protectionMode | Where-Object { $_ -notin 'Ignore', 'None', 'Tpm', 'RecoveryPassword' }) {
		Write-PSFMessage -Level Warning -Message "Volume $($Configuration.Letter) has invalid bitlocker configuration: Unknown options $($invalidOptions -join ',')"
		return
	}

	$bitLockerInfo = Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore
	if ('None' -eq $protectionMode) {
		if ('Off' -eq $bitLockerInfo.ProtectionStatus) { return }
		Write-PSFMessage -Level Warning -Message "Volume $($Configuration.Letter) is configured to be unencrypted but is protected by BitLocker. Drive decryption has not been implemented yet!"
		return
	}

	if ('Off' -eq $bitLockerInfo.ProtectionStatus) {
		$param = @{ RecoveryPasswordProtector = $true }
		if ($protectionMode -contains 'Tpm') { $param = @{ TpmProtector = $true } }

		$null = Enable-BitLocker -MountPoint "$($Configuration.Letter):" @param -Confirm:$false -ErrorAction Stop
	}

	$bitLockerInfo = Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore
	if ($protectionMode -contains 'Tpm' -and $bitLockerInfo.KeyProtector.KeyProtectorType -notcontains 'Tpm') {
		$null = Add-BitLockerKeyProtector -MountPoint "$($Configuration.Letter):" -TpmProtector -Confirm:$false -ErrorAction Stop
	}
	if ($protectionMode -contains 'RecoveryPassword' -and $bitLockerInfo.KeyProtector.KeyProtectorType -notcontains 'RecoveryPassword') {
		$null = Add-BitLockerKeyProtector -MountPoint "$($Configuration.Letter):" -RecoveryPasswordProtector -Confirm:$false -ErrorAction Stop
	}

	# For secondary drives, autounlock
	$bitLockerInfo = Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore
	if ($null -ne $bitLockerInfo.AutoUnlockEnabled -and -not $bitLockerInfo.AutoUnlockEnabled) {
		Enable-BitLockerAutoUnlock -MountPoint "$($Configuration.Letter):" -ErrorAction Stop
	}

	$keyPath = $Configuration.BitLockerKeyPath -replace '%COMPUTERNAME%', $env:COMPUTERNAME
	if (-not $keyPath) { return }

	$bitLockerInfo = Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore
	$keyFileContent = Get-Content -Path $keyPath
	$recoveryPassword = $bitLockerInfo.KeyProtector.RecoveryPassword | Remove-PSFNull
	$hasKey = ($keyFileContent -match $recoveryPassword) -as [bool]
	if ($hasKey) { return }
	"{0}: {1}" -f $Configuration.Letter, $recoveryPassword | Add-Content -Path $keyPath
	#endregion BitLocker
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

	#region Bitlocker
	$protectionMode = 'Ignore'
	if ($Configuration.BitLocker) { $protectionMode = $Configuration.BitLocker }
	# If we don't care, just skip
	if ('Ignore' -eq $protectionMode) { return $true }

	# Short way out if the file doesn't exist yet
	$keyPath = $Configuration.BitLockerKeyPath -replace '%COMPUTERNAME%', $env:COMPUTERNAME
	if ($keyPath -and -not (Test-Path -Path $keyPath)) { return $false }

	$protectionStatus = (Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore).ProtectionStatus
	if ('On' -ne $protectionStatus) { return $protectionMode -eq 'None' }
	
	foreach ($option in $protectionMode) {
		$protector = (Get-BitLockerVolume -MountPoint "$($Configuration.Letter):" -ErrorAction Ignore).KeyProtector | Where-Object KeyProtectorType -EQ $option
		if (-not $protector) {
			Write-PSFMessage "Protector not found: $option"
			return $false
		}

		switch ("$($protector.KeyProtectorType)") {
			'Tpm' {
				# No fail condition - if it is set, that is ok
				break
			}
			'RecoveryPassword' {
				if (-not $keyPath) { break }
				$keyFileContent = Get-Content -Path $keyPath
				$hasKey = ($keyFileContent -match $protector.RecoveryPassword) -as [bool]
				if (-not $hasKey) { return $false }
			}
			default {
				Write-PSFMessage -Level Warning -Message "Invalid Key Protector type! $option is not supported, provide either Tpm or RecoveryPassword protectors!"
				return $false
			}
		}
	}
	#endregion Bitlocker
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
	ParameterOptional  = @(
		'Label'
		'Size'
		'BitLocker' # How should the disk be encrypted? Ignore, None, Tpm, RecoveryPassword (Can combine Tpm and RecoveryPassword)
		'BitLockerKeyPath' # Path to where a recovery key protector will be written
	)
	Tag                = 'volume', 'disk'
}
Register-VMGuestAction @param