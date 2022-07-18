# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Import-VMGuestConfiguration.Config.Import'                   = 'Importing configuration from {0} : {1} ({2})' # $fileObject.FullName, $datumHash.Identity, $datumHash.Action
	'Import-VMGuestConfiguration.File.AccessError'                = 'Failed to access {0}' # $pathItem
	'Import-VMGuestConfiguration.File.Processing'                 = 'Failed to process {0}' # $pathItem
	
	'Invoke-VMGuestConfiguration.Configuration.ActionMissing'     = 'The action {1} required for {0} is missing' # $configuration.Identity, $configuration.Action
	'Invoke-VMGuestConfiguration.Configuration.DependencyNotDone' = 'Cannot process {0} ({1}) as dependency {2} has not been completed. Skipping.' # $configuration.Identity, $configuration.Action, $dependency
	'Invoke-VMGuestConfiguration.Configuration.DoneSkipping'      = 'The configuration {0} ({1}) has already completed, skipping.' # $configuration.Identity, $configuration.Action
	'Invoke-VMGuestConfiguration.Configuration.Execute'           = 'Applying configuration {0} ({1})' # $configuration.Identity, $configuration.Action
	'Invoke-VMGuestConfiguration.Configuration.PostAction.Test'   = 'Validating success of {0} ({1}). Successful: {2}' # $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity]
	'Invoke-VMGuestConfiguration.Configuration.Processing'        = 'Processing configuration {0} ({1})' # $configuration.Identity, $configuration.Action
	'Invoke-VMGuestConfiguration.Configuration.Testing'           = 'Testing configuration {0} ({1})' # $configuration.Identity, $configuration.Action
	'Invoke-VMGuestConfiguration.Configuration.Testing.Completed' = 'Finished testing configuration {0} ({1}) - has been applied: {2}' # $configuration.Identity, $configuration.Action, $currentState[$configuration.Identity]
	'Invoke-VMGuestConfiguration.Finished'                        = 'All configuration items have been applied, deployment complete' # 
	'Invoke-VMGuestConfiguration.InvokeCount.Exceeded'            = 'Maximum number of guest configuration executions exceeded: {0} / {1}' # $currentInvokeCount, $MaxInvokeCount
	'Invoke-VMGuestConfiguration.Processing.Starting'             = 'Starting application of configuration entries' # 
	'Invoke-VMGuestConfiguration.Test.Completed'                  = 'Initial test completed.' # 
	'Invoke-VMGuestConfiguration.Test.Starting'                   = 'Starting initial test of defined configuration entries.' # 
	
	'Register-VMGuestConfiguration.BadParameters'                 = 'Error defining configuration {0} ({1}) - bad parameters. Missing required: {2} | Unknown parameters: {3}' # $Identity, $Action, ($parameterResult.MandatoryMissing -join ','), ($parameterResult.UnknownParameters -join ',')
}