Configuration BaseConfig {

    import-DSCresource -ModuleName PSDesiredStateConfiguration,
        @{ModuleName="xNetworking";ModuleVersion="2.9.0.0"}

    Node DC1 {
                 
        #region - firewall rules 
 
         xFirewall vmpingFWRule 
         { 
             Name = 'vm-monitoring-icmpv4' 
             Action = 'Allow' 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
          
        xFirewall SMB 
         { 
             Name = 'FPS-SMB-In-TCP' 
             Action = 'Allow' 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule1 
         { 
             Name = "RemoteEventLogSvc-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule2 
         { 
             Name = "RemoteEventLogSvc-NP-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule3 
         { 
             Name = "RemoteEventLogSvc-RPCSS-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 

 #end region - firewall rules   

 #enable DSC Analytic Log for troubleshooting

        Script DSCAnalyticLog
        {
            TestScript = {
                            $status = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            if ($status -contains "enabled: true") {return $True} else {return $False}
                        }
            SetScript = {
                            wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true
                        }
            getScript = {
                            $Result = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            return @{Result = $Result}
                        }
        }

        WindowsFeature ServerCore
        {
            Ensure = "Absent"
            Name = "User-Interfaces-Infra"
            IncludeAllSubFeature = $false
            DependsOn = '[xFirewall]vmpingFWRule','[xFirewall]SMB','[xFirewall]RemoteEvtLogFWRule1','[xFirewall]RemoteEvtLogFWRule2','[xFirewall]RemoteEvtLogFWRule3','[Script]DSCAnalyticLog'
        } 
    }
                                                              
}

BaseConfig -OutputPath "C:\DSC\Config"