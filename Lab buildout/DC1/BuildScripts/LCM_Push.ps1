[DSCLocalConfigurationManager()]
Configuration LCM_Push {
    param (
        [Parameter(Mandatory=$True)]
        [string]$ComputerName
        )

    Node $ComputerName {
        Settings {
            ConfigurationMode = 'ApplyAndMonitor'
            RefreshMode = 'Push'
            ActionAfterReboot = 'ContinueConfiguration'
            RebootNodeIfNeeded = $True
            }
        }
    }
LCM_Push -computername DC1 -OutputPath "C:\DSC\LCM"
