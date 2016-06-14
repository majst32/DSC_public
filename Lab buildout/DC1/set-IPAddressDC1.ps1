#Set IP address for private network(s) - must be run ON target box
$IPInfo = Get-NetIPConfiguration | Select-Object -ExpandProperty ipv4address
$startIP = 11
foreach ($IP in $IPInfo) {
    if ($IP.IPAddress.toString() -like "169.254*") {
        new-NetIPAddress -IPAddress "192.168.2.$StartIP" -InterfaceIndex $IP.InterfaceIndex -PrefixLength 24
        $StartIP++
        }
    }

# run on authoring box    
Enter-PSSession 192.168.2.11
Get-NetFirewallRule | Where-Object {$_.Name -match "vm-monitoring-icmpv4"} | Enable-NetFirewallRule
Get-NetFirewallRule | Where-Object {$_.Name -match "FPS-SMB-In-TCP"} | Enable-NetFirewallRule
Get-NetFirewallRule | Where-Object {$_.Name -like "*RemoteEventLogSvc*"} | Enable-NetFirewallRule
rename-computer -ComputerName $env:ComputerName -NewName DC1 -Restart

