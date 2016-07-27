$ConfigData = @{
                AllNodes = @(
                @{
                    NodeName = "*"
                    FWRules = @('vm-monitoring-icmpv4','FPS-SMB-In-TCP','RemoteEventLogSvc-In-TCP','RemoteEventLogSvc-NP-In-TCP','RemoteEventLogSvc-RPCSS-In-TCP')
                }
                @{
                    NodeName = "Test"
                    Role = 'TestServer'
                }
               )
            }

Configuration Consolidate {

import-DSCresource -ModuleName PSDesiredStateConfiguration,
        @{ModuleName="xNetworking";ModuleVersion="2.9.0.0"}

    node $AllNodes.NodeName {
       
       foreach ($Rule in $AllNodes.FWRules) {

            xFirewall $Rule
            {
                Name = $Node.$Rule
                Action = 'Allow'
                Direction = 'Inbound'
                Enabled = $True
                Ensure = 'Present'
            }
        }
    }
}

Consolidate -configurationData $ConfigData -outputpath "C:\DSC\Config"

        