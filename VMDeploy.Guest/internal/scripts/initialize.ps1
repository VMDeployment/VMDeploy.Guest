$paramSetPSFLoggingProvider = @{
	Name           = 'eventlog'
	InstanceName   = 'VMDeploy.Guest'
	IncludeModules = 'VMDeploy.Guest'
	Source         = 'VMDeploy.Guest'
	LogName        = 'VMDeployment'
	Enabled        = $true
	Wait           = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

$log = [System.Diagnostics.EventLog]::new("VMDeployment")
$log.MaximumKilobytes = 1MB