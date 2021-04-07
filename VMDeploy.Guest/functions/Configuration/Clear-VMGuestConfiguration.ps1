function Clear-VMGuestConfiguration {
	[CmdletBinding()]
	param ()
	
	process {
		$script:configurations.Clear()
	}
}
