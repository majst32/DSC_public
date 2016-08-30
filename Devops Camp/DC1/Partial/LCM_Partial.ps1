[DSCLocalConfigurationManager()]
Configuration LCM_Partial {
    param (
        [Parameter(Mandatory=$True)]
        [string]$ComputerName
        )

    Node $ComputerName {
        PartialConfiguration BaseConfig {
            Description = 'Firewall rules, logging, and server core'
            RefreshMode = 'Push'
            }

        PartialConfiguration DC1Config {
            Description = 'First domain controller in domain'
            RefreshMode = 'Push'
            DependsOn = '[PartialConfiguration]BaseConfig'
            }
        
        Settings {
            ConfigurationMode = 'ApplyAndMonitor'
            ActionAfterReboot = 'ContinueConfiguration'
            RebootNodeIfNeeded = $True
            }
        }
    }
LCM_Partial -computername DC1 -OutputPath "C:\DSC\LCM"
