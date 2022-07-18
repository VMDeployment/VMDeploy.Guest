function Import-VMGuestConfiguration {
<#
	.SYNOPSIS
		Imports configuration files defining guest configuration entries.
	
	.DESCRIPTION
		Imports configuration files defining guest configuration entries.
		The files imported can be either json or psd1 format.
		They must contain an array of entries, each entry matching the parameters of Register-VMGuestConfiguration.
	
	.PARAMETER Path
		Path to the file(s) to load.
		Wildcard supported.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Import-VMGuestConfiguration -Path '.\config.json'
	
		Loads the file "config.json" from the current folder as configuration.
#>
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
					Register-VMGuestConfiguration @datumHash -ErrorAction Stop -EnableException
				} -Target $datumHash -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
			}
			#endregion Process/Load Configuration Entries
		}
	}
}