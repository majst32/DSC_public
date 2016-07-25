Set-DscLocalConfigurationManager -ComputerName Pull -Path "C:\DSC\LCM" -Verbose -Force

copy-item "C:\Program Files\WindowsPowershell\Modules\xNetworking" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xPSDesiredStateConfiguration" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
Copy-Item "C:\Program Files\WindowsPowershell\Modules\xWebAdministration" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force

Remove-DscConfigurationDocument -CimSession Pull -Stage Current
Remove-DscConfigurationDocument -CimSession Pull -Stage Pending 
Start-DscConfiguration -ComputerName Pull -Path "C:\DSC\Config" -Verbose -wait -Force
