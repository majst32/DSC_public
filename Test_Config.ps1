Configuration DisableSSLConfig {
    
    param (
        [parameter(Mandatory=$True)]
        [string] $Guid
    )

    Node $guid {
    
        Registry Disable_SSL_2 {
            Ensure = 'Present'
            Key = "HKEY_Local_Machine\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
            ValueName = "Enabled"
            ValueType = 'Dword'
            ValueData = "0"
        }

        Registry Disable_SSL_3_Server {
            Ensure = 'Present'
            Key = "HKEY_Local_Machine\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
            ValueName = "Enabled"
            ValueType = 'Dword'
            ValueData = "0"
        }

        Registry Disable_SSL_3_Client {
            Ensure = 'Present'
            Key = "HKEY_Local_Machine\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
            ValueName = "Enabled"
            ValueType = 'Dword'
            ValueData = "0"
        }
    }
}

$Guid=Get-DscLocalConfigurationManager -CimSession s1| Select-Object -ExpandProperty ConfigurationID
DisableSSLConfig -guid  $Guid -OutputPath "C:\DSC\Config"

     