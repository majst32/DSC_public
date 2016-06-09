Install-WindowsFeature -Name RSAT-AD-Tools,RSAT-ADCS,RSAT-DHCP,RSAT-DNS-Server,RSAT-DFS-Mgmt-Con,GPMC
find-module PSWindowsUpdate | install-module
import-module PSWindowsUpdate
Get-WUInstall -IgnoreUserInput -verbose

#Create DSC Folder Structure
new-item -path "C:\DSC\Config" -ItemType directory
new-item -path "C:\DSC\LCM" -ItemType directory

#Set IP address for private network(s)
$IPInfo = Get-NetIPConfiguration | Select-Object -ExpandProperty ipv4address
$StartIP=10
foreach ($IP in $IPInfo) {
    if ($IP.IPAddress.toString() -like "169.254*") {
        new-NetIPAddress -IPAddress "192.168.2.$StartIP" -InterfaceIndex $IP.InterfaceIndex -PrefixLength 24
        $StartIP++
        }
    }

rename-computer -ComputerName $env:ComputerName -NewName Auth -Restart

#enable ping        
Get-NetFirewallRule | Where-Object {$_.Name -match "vm-monitoring-icmpv4"} | Enable-NetFirewallRule

#add remotes to trusted hosts list
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force


