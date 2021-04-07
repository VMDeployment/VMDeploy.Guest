function Unregister-VMGuestAction {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('VMDeploy.Guest.Action')]
		[string[]]
		$Name
	)
	
	process {
		foreach ($nameEntry in $Name) {
			$script:actions.Remove($nameEntry)
		}
	}
}
