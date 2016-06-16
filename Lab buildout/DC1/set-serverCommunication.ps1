function set-ServerCommunication {

param (
    [parameter(Mandatory=$True)]
    [string]$NewName
    )

Get-NetFirewallRule | Where-Object {$_.Name -match "vm-monitoring-icmpv4"} | Enable-NetFirewallRule
Get-NetFirewallRule | Where-Object {$_.Name -match "FPS-SMB-In-TCP"} | Enable-NetFirewallRule
Get-NetFirewallRule | Where-Object {$_.Name -like "*RemoteEventLogSvc*"} | Enable-NetFirewallRule
wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true
rename-computer -ComputerName $env:ComputerName -NewName $NewName -Restart

}
set-ServerCommunication -NewName DC1