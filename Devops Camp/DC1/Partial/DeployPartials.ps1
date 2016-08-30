cd 'C:\Powershell\DSC_public\Devops Camp\DC1\Partial'

.\LCM_Partial.ps1
Set-DscLocalConfigurationManager -ComputerName DC1 -Path "C:\DSC\LCM" -Verbose

.\BaseConfig.ps1
Publish-DscConfiguration -Path "C:\DSC\Config" -ComputerName DC1

.\DC1Config.ps1
Publish-DscConfiguration -Path "C:\DSC\Config" -ComputerName DC1

copy-item "C:\Program Files\WindowsPowerShell\Modules\xActiveDirectory" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules\xActiveDirectory" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xADCSDeployment" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules" -Recurse -force
copy-item "C:\Program Files\WindowsPowershell\Modules\xNetworking" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force
copy-item "C:\Program Files\WindowsPowershell\Modules\xDHCPServer" -Destination "\\dc1\C$\Program Files\WindowsPowershell\Modules" -Recurse -Force

Start-DscConfiguration -ComputerName DC1 -Verbose -UseExisting


