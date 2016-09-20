[DSCLocalConfigurationManager()]
Configuration LCM_Push {
    param (
        [Parameter(Mandatory=$True)]
        [string]$ComputerName,

        [Parameter(Mandatory=$True)]
        [string]$CertThumbprint
        )

    Node $ComputerName {
        Settings {
            ConfigurationMode = 'ApplyAndMonitor'
            RefreshMode = 'Push'
            ActionAfterReboot = 'ContinueConfiguration'
            RebootNodeIfNeeded = $True
            CertificateID = $CertThumbprint
            }
        }
    }
LCM_Push -computername PULL -outputpath "C:\dsc\LCM" -certThumbprint (invoke-command -ComputerName Pull {Get-ChildItem -Path "Cert:\LocalMachine\My" -DocumentEncryptionCert | Select-object -expandProperty Thumbprint})
