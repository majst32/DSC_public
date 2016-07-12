#push DC server config
cd 'C:\Powershell\DSC_public\Lab buildout\Pull'

enter-pssession Pull
#open set-servercommunication and run it
Exit-PSSession

.\set-DomainObjects 

Set-DscLocalConfigurationManager -ComputerName Pull -Path "C:\DSC\LCM" -Verbose -Force

copy-item "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xADCSDeployment" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -force
copy-item "C:\Program Files\WindowsPowershell\Modules\xNetworking" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
Copy-Item "C:\Program Files\WindowsPowershell\Modules\xComputerManagement" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force

Remove-DscConfigurationDocument -CimSession Pull -Stage Current
Remove-DscConfigurationDocument -CimSession Pull -Stage Pending 
Start-DscConfiguration -ComputerName Pull -Path "C:\DSC\Config" -Verbose -wait -Force
