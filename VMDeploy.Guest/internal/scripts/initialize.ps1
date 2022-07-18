$paramSetPSFLoggingProvider = @{
	Name		   = 'eventlog'
	InstanceName   = 'VMDeploy.Guest'
	IncludeModules = 'VMDeploy.Guest'
	Source		   = 'VMDeploy.Guest'
	LogName	       = 'VMDeployment'
	Enabled	       = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider