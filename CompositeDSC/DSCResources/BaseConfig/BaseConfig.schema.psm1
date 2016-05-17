configuration BaseConfig
{
    param (
        [string] $WSUSUrl
        )
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
            ValueData = $WSUSURL
            ValueType = 'String'
            DependsOn = '[Registry]HKCU_WSUS_del_3'
        }

        Registry HKLM_WSUS_add_2 {
            Key = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'WUStatusServer'
            Ensure = 'Present'
            ValueData = $WSUSUrl
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


} 