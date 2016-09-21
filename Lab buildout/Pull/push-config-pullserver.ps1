.\LCM_Push.ps1

Set-DscLocalConfigurationManager -ComputerName Pull -Path "C:\DSC\LCM" -Verbose -Force

invoke-command -ComputerName Pull {Get-ChildItem -path "Cert:\LocalMachine\My" -documentEncryptionCert | export-certificate -filepath "C:\Program Files\WindowsPowershell\Pull.cer"}
copy-item "\\pull\C$\Program Files\WindowsPowershell\pull.cer" -Destination "C:\DSC\Certs" -Force

.\PullConfig.ps1

copy-item "C:\Program Files\WindowsPowershell\Modules\xNetworking" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xPSDesiredStateConfiguration" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
Copy-Item "C:\Program Files\WindowsPowershell\Modules\xWebAdministration" -Destination "\\Pull\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
copy-item "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -Destination "\\pull\C$\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Recurse -Force

Remove-DscConfigurationDocument -CimSession Pull -Stage Current
Remove-DscConfigurationDocument -CimSession Pull -Stage Pending 
Start-DscConfiguration -ComputerName Pull -Path "C:\DSC\Config" -Verbose -wait -Force
