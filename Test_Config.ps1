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

        #Know this probably won't work if WMF5 isn't already on the target box
        #only using it for depends on example
        File fWMFv5 {
            Type = 'Directory'
            Ensure = 'Present'
            SourcePath ="\\fileshare\Files"
            DestinationPath = "C:\_File_Area"
            MatchSource = $True
            Recurse = $True
            #would like to include checksum
        }

        xHotfix hfWMF5 {
            Id = 'KB3134758'
            Path ="C:\_File_Area\Windows Management Framework 5.0 RTM\Win8.1AndW2K12R2-KB3134758-x64.msu"
            Ensure = 'Present'
            DependsOn = '[File]fWMFv5'
        }

    }
}


$Guid=Get-DscLocalConfigurationManager -CimSession s1| Select-Object -ExpandProperty ConfigurationID
SSLWMF5Config -guid  $Guid -SchannelSubkey 'SSL 2.0\Server','SSL 3.0\Client','SSL 3.0\Server' -OutputPath "C:\DSC\Config"

     