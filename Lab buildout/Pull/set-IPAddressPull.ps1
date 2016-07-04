#Set IP address for private network(s) - must be run ON target box - copy to target
$IPInfo = Get-NetIPConfiguration | Select-Object -ExpandProperty ipv4address
$startIP = 12
foreach ($IP in $IPInfo) {
    if ($IP.IPAddress.toString() -like "169.254*") {
        new-NetIPAddress -IPAddress "192.168.2.$StartIP" -InterfaceIndex $IP.InterfaceIndex -PrefixLength 24
        $StartIP++
        }
    }


