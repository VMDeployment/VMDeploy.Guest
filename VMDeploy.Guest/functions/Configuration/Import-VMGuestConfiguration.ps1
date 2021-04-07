function Import-VMGuestConfiguration {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidateScript('PSFramework.Validate.FSPath.File', ErrorString = 'PSFramework.Validate.FSPath.File')]
		[Alias('FullName')]
		[string[]]
		$Path,
		
		[switch]
		$EnableException
	)
	
	begin {
		$guestConfigParameters = (Get-Command Register-VMGuestConfiguration).Parameters.Values.Name
	}
	process {
		foreach ($pathItem in Resolve-PSFPath -Path $Path -Provider FileSystem) {
			$fileObject = Get-Item -Path $pathItem
			if ($fileObject.PSIsContainer) { continue }
			Write-PSFMessage -Level Verbose -String 'Import-VMGuestConfiguration.File.Processing' -StringValues $pathItem -Target $pathItem
			
			#region Read Config File
			try {
				$data = switch ($fileObject.Extension) {
					'.psd1' {
						Import-PSFPowerShellDataFile -Path $fileObject.FullName -ErrorAction Stop
					}
					default {
						Get-Content -Path $fileObject.FullName -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
					}
				}
			}
			catch {
				Stop-PSFFunction -String 'Import-VMGuestConfiguration.File.AccessError' -StringValues $pathItem -Target $pathItem -EnableException $EnableException -Continue -ErrorRecord $_
			}
			#endregion Read Config File
			
			#region Process/Load Configuration Entries
			foreach ($datum in $data) {
				$datumHash = $datum | ConvertTo-PSFHashtable -Include $guestConfigParameters
				$datumHash.Source = $fileObject.BaseName
				if ($datumHash.Parameters) { $datumHash.Parameters = $datumHash.Parameters | ConvertTo-PSFHashtable }
				
				Invoke-PSFProtectedCommand -ActionString 'Import-VMGuestConfiguration.Config.Import' -ActionStringValues $fileObject.FullName, $datumHash.Identity, $datumHash.Action -ScriptBlock {
					Register-VMGuestConfiguration @datumHash -ErrorAction Stop
				} -Target $datumHash -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
			}
			#endregion Process/Load Configuration Entries
		}
	}
}
