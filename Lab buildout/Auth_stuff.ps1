Install-WindowsFeature -Name RSAT-AD-Tools,RSAT-ADCS,RSAT-DHCP,RSAT-DNS-Server,RSAT-DFS-Mgmt-Con
find-module PSWindowsUpdate | install-module
import-module PSWindowsUpdate
Get-WUInstall -IgnoreUserInput -verbose