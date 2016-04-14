Configuration SSLWMF5Config {
   
    Import-DscResource -Name xHotfix -ModuleName xWindowsUpdate

        Node $AllNodes.NodeName {
       
            foreach ($S in $Node.SChannelSubkey) {

                Registry $S {
                    Ensure = 'Present'
                    Key = "HKEY_Local_Machine\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$S)"
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



SSLWMF5Config -ConfigurationData "C:\powershell\config_data_test.psd1" -OutputPath "C:\DSC\Config"

     