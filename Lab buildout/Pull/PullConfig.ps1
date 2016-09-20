$ConfigData = @{
                AllNodes = @(
                @{
                    NodeName = "*"
                    Domain = "blah.com"
                    DomainDN = "dc=blah,dc=com"
                    ServersOU = 'OU=Servers,dc=blah,dc=com'
                    GroupsOU = 'OU=Groups,dc=blah,dc=com'
                    PSDSCAllowDomainUser = $True
                },
                @{
                    NodeName = "Pull"
                    Role = "PullServer"
                    DNSServerIP = '192.168.2.11'
                    sAMAccountName = "Pull$"
                    PullServerEndPointName = 'PSDSCPullServer' 
                    PullserverPort = 8080                       
                    PullserverPhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer" 
                    PullserverModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
                    PullServerConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration" 
                    PullServerThumbPrint = Invoke-Command -ComputerName pull {Get-ChildItem Cert:\LocalMachine\My | Where-Object {($_.EnhancedKeyUsageList -like "Server Authentication*") -and ($_.Issuer -like "CN=blahblahblah root*")}} | Select-Object -expandproperty Thumbprint
                    Thumbprint = Invoke-Command -ComputerName pull {Get-ChildItem Cert:\LocalMachine\My -DocumentEncryptionCert | Select-Object -expandproperty Thumbprint}
                    CertificateFile = "C:\DSC\Certs\Pull.cer"
                }
                
            )
        }

Configuration PullConfig {

param (
    [parameter(Mandatory=$True)]
    [pscredential]$Credential
    )

    import-DSCresource -ModuleName PSDesiredStateConfiguration,CompositeBase,
        @{ModuleName="xNetworking";ModuleVersion="2.9.0.0"},
        @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion="3.12.0.0"},
        @{ModuleName="xWebAdministration";ModuleVersion="1.12.0.0"},
        @{ModuleName="xActiveDirectory";ModuleVersion="2.11.0.0"}

    
    node $AllNodes.NodeName {
    
    BaseConfig Base {}

    }
   
    node $AllNodes.where{$_.Role -eq "PullServer"}.NodeName {  
    
        WindowsFeature RSATADPowershell
        {
            Name = 'RSAT-AD-Powershell'
            Ensure = 'Present'
        }
        
        xWaitForADDomain WaitForDomain
        {
            DomainName = $Node.Domain
            RetryIntervalSec = 10
            RetryCount = 10
        }
        
        xADUser WebServerOperator
        {
            DomainName = $Node.domain
            DependsOn = '[xWaitForADDomain]WaitForDomain'
            UserName = 'WebSvrOperator'
            Ensure = 'Present'
            GivenName = "Web"
            Surname = "Server Operator"
            DomainAdministratorCredential = $credential
        }
       
        xADGroup WebServerOperatorsGroup
        {
            GroupName = 'Web Server Operators'
            Ensure = 'Present'
            Credential = $Credential
            GroupScope = 'Global'
            Category = 'Security'
            DependsOn = '[xADUser]WebServerOperator'
            Path = $Node.GroupsOU
            Members = 'WebSvrOperator'
        }
  
        xDNSServerAddress SetDNSServer
        {
            Address = $Node.DNSServerIP
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }
 
        WindowsFeature DSCServiceFeature { 
             Ensure = "Present" 
             Name   = "DSC-Service" 
             } 
 
        WindowsFeature ASP { 
          
             Ensure = "Absent" 
             Name = "Web-ASP" 
             DependsOn = '[WindowsFeature]DSCServiceFeature' 
         } 

 
        WindowsFeature CGI { 
          
             Ensure = "Absent" 
             Name = "Web-CGI" 
             DependsOn = '[WindowsFeature]DSCServiceFeature' 
         } 
 
 
        WindowsFeature IPDomainRestrictions { 
          
             Ensure = "Absent" 
             Name = "Web-IP-Security" 
             DependsOn = '[WindowsFeature]DSCServiceFeature' 
         } 
 
 
 # !!!!! # GUI Remote Management of IIS requires the following: - people always forget this until too late 
 
 
         WindowsFeature Management { 
 
             Name = 'Web-Mgmt-Service' 
             Ensure = 'Present' 
         } 
 
 
         Registry RemoteManagement { # Can set other custom settings inside this reg key 
             Key = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server' 
             ValueName = 'EnableRemoteManagement' 
             ValueType = 'Dword' 
             ValueData = '1' 
             DependsOn = @('[WindowsFeature]DSCServiceFeature','[WindowsFeature]Management') 
        } 
 
 
        Service StartWMSVC { 
            Name = 'WMSVC' 
            StartupType = 'Automatic' 
            State = 'Running' 
            DependsOn = '[Registry]RemoteManagement' 
        } 
  
#       # Often, It's common to disable the default website and then create your own 
         # - dont do this to Pull Servers, ADCS or other Services that use the default website 
 
        xWebsite DefaultSite { 
            Name            = "Default Web Site" 
            State           = "Started" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[WindowsFeature]DSCServiceFeature" 
        } 

         xDscWebService PSDSCPullServer { 
            Ensure = "Present" 
            EndpointName = $Node.PullServerEndPointName 
            Port = $Node.PullServerPort   
            PhysicalPath = $Node.PullserverPhysicalPath 
            CertificateThumbPrint =  $Node.PullServerThumbprint
            ModulePath = $Node.PullServerModulePath 
            ConfigurationPath = $Node.PullserverConfigurationPath 
            State = "Started" 
            DependsOn = "[WindowsFeature]DSCServiceFeature" 
            }             

        File RegistrationKey
        {
            Ensure = "Present"
            DestinationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents  = "b9b36d42-84c0-42ae-b028-779a49bd9f22"
            Type = "File"
        }
        
     }   


}

PullConfig -configurationData $ConfigData -outputpath "C:\DSC\Config" -credential (Get-Credential -UserName "BLAH\Administrator" -message "Credential for adding users to AD")
