 $ConfigData=@{
    AllNodes = @(
        @{
            NodeName  = "*"
            WSUSUrl = "http://w1:8530"

        },
        @{
            NodeName = 'S1'
            GUID = Get-DscLocalConfigurationManager -CimSession S1 | Select-Object -ExpandProperty ConfigurationID
        },
        @{
            NodeName = 'S2'
            Role     = @('DHCPServer','DHCPServer1')
            GUID = Get-DscLocalConfigurationManager -CimSession S2 | Select-Object -ExpandProperty ConfigurationID
        }, 
        @{
            NodeName = 'S3'
            Role     = 'DHCPServer'
            GUID = Get-DscLocalConfigurationManager -CimSession S3 | Select-Object -ExpandProperty ConfigurationID
        } 

    );
}
  
configuration BuildOut {
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xDHCPServer
    
    node $AllNodes.GUID {
        
   ###########################################START WSUS####################################
        
        Registry HKCU_WSUS_del_1 {
        Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        ValueName = 'ProxyEnable'
        Ensure = "Absent"
        } 

        Registry HKCU_WSUS_del_2 {
        Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        ValueName = 'AutoConfigURL'
        Ensure = "Absent"
        DependsOn = '[Registry]HKCU_WSUS_del_1'
        }

        Registry HKCU_WSUS_del_3 {
        Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        ValueName = 'ProxyServer'
        Ensure = "Absent"
        DependsOn = '[Registry]HKCU_WSUS_del_2'
        }

        Registry HKLM_WSUS_add_1 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'WUServer'
            Ensure = 'Present'
            ValueData = $Node.WSUSUrl
            ValueType = 'String'
            DependsOn = '[Registry]HKCU_WSUS_del_3'
        }

        Registry HKLM_WSUS_add_2 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'WUStatusServer'
            Ensure = 'Present'
            ValueData = $Node.WSUSUrl
            ValueType = 'String'
            DependsOn = '[Registry]HKLM_WSUS_add_1'
        }

        Registry HKLM_WSUS_add_3 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'NoAutoUpdate'
            Ensure = 'Present'
            ValueData = '1'
            ValueType = 'Dword'
            DependsOn = '[Registry]HKLM_WSUS_add_2'
        }

        Registry HKLM_WSUS_add_4 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'AUOptions'
            Ensure = 'Present'
            ValueData = '3'
            ValueType = 'Dword'
            DependsOn = '[Registry]HKLM_WSUS_add_3'
        }

        Registry HKLM_WSUS_add_5 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'UseWUServer'
            Ensure = 'Present'
            ValueData = '1'
            ValueType = 'Dword'
            DependsOn = '[Registry]HKLM_WSUS_add_4'
        }

        Registry HKLM_WSUS_add_6 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'ScheduledInstallDay'
            Ensure = 'Present'
            ValueData = '0'
            ValueType = 'Dword'
            DependsOn = '[Registry]HKLM_WSUS_add_5'
        }

        Registry HKLM_WSUS_add_7 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'ScheduledInstallTime'
            Ensure = 'Present'
            ValueData = '3'
            ValueType = 'Dword'
            DependsOn = '[Registry]HKLM_WSUS_add_6'
        }

        Service WSUS {
            Name = 'wuauserv'
            DependsOn = '[Registry]HKLM_WSUS_add_7'
            Ensure = 'Present'
            StartupType = 'Automatic'
            State = 'Running'
        }


#####After setting all the registry settings, need to recycle wuauserv, how do you do this?
#####Can't set it to stopped and then started with a DSC resource :(
#####Then need it to install patches########################################################

#########################################END WSUS###########################################
    
#End Node     
    }

    node $AllNodes.Where{$_.Role -eq 'DHCPServer'}.GUID {

###########################################START DHCP####################################
#Should statically assign IP address first
#Should set WSUS and update after
#########################################################################################

    WindowsFeature DHCP {
        Name = 'DHCP'
        Ensure = 'Present'
    }

    WindowsFeature DHCPMgmt {
        Name = 'RSAT-DHCP'
        Ensure =  'Present'
    }

   }

node $AllNodes.Where{$_.Role -eq 'DHCPServer1'}.GUID {

    xDHCPServerScope TestScope {
        IPEndRange = '192.168.2.254'
        IPStartRange = '192.168.2.1'
        Name = 'TestScope'
        SubnetMask = '255.255.255.0'
        AddressFamily = 'IPv4'
        DependsOn = '[WindowsFeature]DHCP'
        Ensure = 'Present'
        LeaseDuration = '10'
        State = 'Inactive'
    }
}

################Need cross-machine dependency for DHCP to be installed on both servers####

###########################################END DHCP####################################

 
}

BuildOut -ConfigurationData $ConfigData -OutputPath "C:\DSC\Config"
