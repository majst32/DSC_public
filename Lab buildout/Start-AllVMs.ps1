param (
    [parameter(Mandatory=$True)]
    [string]$DC,

    [string[]]$MbrSvrs
    )

if ((get-VM -name $DC).State -eq "Off") {Start-VM -Name $DC}
start-sleep -Seconds 5

foreach ($VM in $MbrSvrs) {
    if ((get-VM -name $VM).State -eq "Off") {Start-VM -Name $VM}
    }
