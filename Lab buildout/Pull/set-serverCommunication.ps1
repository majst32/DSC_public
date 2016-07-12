function set-ServerCommunication {

param (
    [parameter(Mandatory=$True)]
    [string]$NewName,

    [parameter(Mandatory=$True)]
    [string]$Domain,

    [parameter(Mandatory=$True)]
    [pscredential]$ADCreds
    )
#need to enter-PSSession first 

#May need this before DSC, to copy the modules.
Get-NetFirewallRule | Where-Object {$_.Name -match "FPS-SMB-In-TCP"} | Enable-NetFirewallRule

#FW holes included here for investigation of DSC apply issues, is also in DSC config.
Get-NetFirewallRule | Where-Object {$_.Name -match "vm-monitoring-icmpv4"} | Enable-NetFirewallRule
Get-NetFirewallRule | Where-Object {$_.Name -like "*RemoteEventLogSvc*"} | Enable-NetFirewallRule
wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true

#Rename and add to domain
rename-computer -ComputerName $env:ComputerName -NewName $NewName
add-computer -DomainName $Domain -Credential $ADCreds -restart

}

$Domain = "BLAH"
$ADCreds = Get-Credential -Message "Enter Domain Credentials" -UserName "$Domain\Administrator"
set-ServerCommunication -NewName Pull -domain $Domain -ADCreds $ADCreds