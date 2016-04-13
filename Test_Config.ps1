Configuration SSLWMF5Config {
    
    param (
        [parameter(Mandatory=$True)]
        [string] $Guid,

        [parameter(Mandatory=$True)]
        [string[]] $SchannelSubkey
    )

    Import-DscResource -Name xHotfix -ModuleName xWindowsUpdate

    Node $guid {
    
        foreach ($s in $SchannelSubkey) {
            
            Registry $s {
                Ensure = 'Present'
                Key = "HKEY_Local_Machine\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$s"
                ValueName = "Enabled"
                ValueType = 'Dword'
                ValueData = "0"
            }
        }
    }
}


$Guid=Get-DscLocalConfigurationManager -CimSession s1| Select-Object -ExpandProperty ConfigurationID
SSLWMF5Config -guid  $Guid -SchannelSubkey 'SSL 2.0\Server','SSL 3.0\Client','SSL 3.0\Server' -OutputPath "C:\DSC\Config"

     