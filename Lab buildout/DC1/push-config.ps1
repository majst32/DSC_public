#push DC server config

Set-DscLocalConfigurationManager -ComputerName DC1 -Path "C:\DSC\LCM" -Verbose -Force

copy-item "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xADCSDeployment" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules" -Recurse

Remove-DscConfigurationDocument -CimSession DC1 -Stage Pending
Start-DscConfiguration -ComputerName DC1 -Path "C:\DSC\Config" -Verbose -wait
