#push DC/Pull server config

copy-item "C:\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Recurse
Remove-DscConfigurationDocument -CimSession DC1 -Stage Pending
Start-DscConfiguration -ComputerName DC1 -Path "C:\DSC\Config" -Verbose -wait
