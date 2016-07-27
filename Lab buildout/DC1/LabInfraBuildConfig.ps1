$ConfigData = @{
                AllNodes = @(
                @{
                    NodeName = "*"
                    Domain = "blah.com"
                    DomainDN = "dc=blah,dc=com"
                    ServersOU = 'OU=Servers,dc=blah,dc=com'
                },
                @{
                    NodeName = "DC1"
                    Role = "AD_ADCS"
                    PSDSCAllowPlainTextPassword = $True
                    PSDSCAllowDomainUser = $True
                    DCDatabasePath = "C:\NTDS"
                    DCLogPath = "C:\NTDS"
                    SysvolPath = "C:\Sysvol"
                    CACN = "blahblahblah root"
                    CADNSuffix = "C=US,L=Somecity,S=Pennsylvania,O=Test Corp"
                    CADatabasePath = "C:\windows\system32\CertLog"
                    CALogPath = "C:\CA_Logs"
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
                }
            )
        }

Configuration LabInfraBuild {

param (
    [parameter(Mandatory=$True)]
    [pscredential]$EACredential,

    [parameter(Mandatory=$True)]
    [pscredential]$SafeModeAdminPW
    )

    import-DSCresource -ModuleName PSDesiredStateConfiguration,
        @{ModuleName="xActiveDirectory";ModuleVersion="2.11.0.0"},
        @{ModuleName="xNetworking";ModuleVersion="2.9.0.0"},
        @{ModuleName="XADCSDeployment";ModuleVersion="1.0.0.1"},
        @{ModuleName="xComputerManagement";ModuleVersion="1.6.0.0"},
        @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion="3.12.0.0"},
        @{ModuleName="xWebAdministration";ModuleVersion="1.12.0.0"}
    
    node $AllNodes.NodeName {
       
#region - firewall rules 
 
         xFirewall vmpingFWRule 
         { 
             Name = 'vm-monitoring-icmpv4' 
             Action = 'Allow' 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
          
        xFirewall SMB 
         { 
             Name = 'FPS-SMB-In-TCP' 
             Action = 'Allow' 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule1 
         { 
             Name = "RemoteEventLogSvc-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule2 
         { 
             Name = "RemoteEventLogSvc-NP-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 
 
         xFirewall RemoteEvtLogFWRule3 
         { 
             Name = "RemoteEventLogSvc-RPCSS-In-TCP" 
             Action = "Allow" 
             Direction = 'Inbound' 
             Enabled = $True 
             Ensure = 'Present' 
         } 

 #end region - firewall rules   

 #enable DSC Analytic Log for troubleshooting

        Script DSCAnalyticLog
        {
            TestScript = {
                            $status = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            if ($status -contains "enabled: true") {return $True} else {return $False}
                        }
            SetScript = {
                            wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true
                        }
            getScript = {
                            $Result = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            return @{Result = $Result}
                        }
        }

        WindowsFeature ServerCore
        {
            Ensure = "Absent"
            Name = "User-Interfaces-Infra"
            IncludeAllSubFeature = $false
            DependsOn = '[xFirewall]vmpingFWRule','[xFirewall]SMB','[xFirewall]RemoteEvtLogFWRule1','[xFirewall]RemoteEvtLogFWRule2','[xFirewall]RemoteEvtLogFWRule3','[Script]DSCAnalyticLog'
        } 
                                                              
    }
   
    node $AllNodes.Where{$_.Role -eq "AD_ADCS"}.NodeName {
        
        WindowsFeature ADDS
        {
           Ensure = "Present"
           Name   = "AD-Domain-Services"
           DependsOn = '[WindowsFeature]ServerCore'
        }

        WindowsFeature GPMC
        {
            Ensure = 'Present'
            Name = 'GPMC'
            DependsOn = '[WindowsFeature]ServerCore'
        }
 
 #DCPromo
        
        xADDomain FirstDC
        {
            DomainName = $Node.Domain
            DomainAdministratorCredential = $EACredential
            SafemodeAdministratorPassword = $SafeModeAdminPW
            DatabasePath = $Node.DCDatabasePath
            LogPath = $Node.DCLogPath
            SysvolPath = $Node.SysvolPath 
            DependsOn = '[WindowsFeature]ADDS'
        }      

# Add OU for groups

         xADOrganizationalUnit GroupsOU
        {
            Name = 'Groups'
            Path = $Node.DomainDN
            DependsOn = '[xADDomain]FirstDC'
            Ensure = 'Present'
            ProtectedFromAccidentalDeletion = $True
            Credential = $EaCredential
        }

# Add OU for Member Servers

         xADOrganizationalUnit ServersOU
        {
            Name = 'Servers'
            Path = $Node.DomainDN
            DependsOn = '[xADDomain]FirstDC'
            Ensure = 'Present'
            ProtectedFromAccidentalDeletion = $True
            Credential = $EaCredential
        }

#Pre-add member servers to AD

        $MbrSvrs = $AllNodes.Where{$_.NodeName -notmatch "DC1"}
        foreach ($M in $MbrSvrs)
            {
            
            script "AddMbrSvr_$($M.NodeName)" {
                Credential = $EACredential
                DependsOn = '[xADOrganizationalUnit]ServersOU'
                TestScript = {
                                try {
                                    Get-ADComputer -Identity $Using:M.NodeName -ErrorAction Stop
                                    Return $True
                                    }
                                catch {
                                    return $False
                                    }
                            }
                SetScript = {
                                New-ADComputer -Name $Using:M.NodeName -path $Using:M.ServersOU
                            }
                GetScript = {
                                try {
                                    return (Get-ADComputer -Identity $Using:M.NodeName -ErrorAction Stop)
                                    }
                                catch {
                                    return @{Result = $null}
                                    }
                            }
                }
            }

#Add Web Servers group - add pull server as member later

         xADGroup WebServerGroup
        {
            GroupName = 'Web Servers'
            GroupScope = 'Global'
            DependsOn = '[xADOrganizationalUnit]GroupsOU'
            Members = $AllNodes.Where{$_.Role -eq "PullServer"}.sAMAccountName
            Credential = $EACredential
            Category = 'Security'
            Path = "OU=Groups,$($Node.DomainDN)"
            Ensure = 'Present'
        }

#region - Add GPO for PKI AutoEnroll
        script CreatePKIAEGpo
        {
            Credential = $EACredential
            TestScript = {
                            if ((get-gpo -name "PKI AutoEnroll" -ErrorAction SilentlyContinue) -eq $Null) {
                                return $False
                            } 
                            else {
                                return $True}
                        }
            SetScript = {
                            new-gpo -name "PKI AutoEnroll"
                        }
            GetScript = {
                            $GPO= (get-gpo -name "PKI AutoEnroll")
                            return @{Result = $GPO}
                        }
            DependsOn = '[xADDomain]FirstDC'
        }
        
        script setAEGPRegSetting1
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -ErrorAction SilentlyContinue).Value -eq 7) {
                                return $True
                            }
                            else {
                                return $False
                            }
                        }
            SetScript = {
                            Set-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -Value 7 -Type DWord
                        }
            GetScript = {
                            $RegVal1 = (Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy")
                            return @{Result = $RegVal1}
                        }
            DependsOn = '[Script]CreatePKIAEGpo'
        }

        script setAEGPRegSetting2 
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -ErrorAction SilentlyContinue).Value -eq 10) {
                                return $True
                                }
                            else {
                                return $False
                                 }
                         }
            SetScript = {
                            Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -value 10 -Type DWord
                        }
            GetScript = {
                            $Regval2 = (Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent")
                            return @{Result = $RegVal2}
                        }
            DependsOn = '[Script]setAEGPRegSetting1'

        }
                                  
        script setAEGPRegSetting3
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -ErrorAction SilentlyContinue).value -match "MY") {
                                return $True
                                }
                            else {
                                return $False
                                }
                        }
            SetScript = {
                            Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -value "MY" -Type String
                        }
            GetScript = {
                            $RegVal3 = (Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames")
                            return @{Result = $RegVal3}
                        }
            DependsOn = '[Script]setAEGPRegSetting2'
        }
      
      script setAEGPRegSetting4
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\SystemCertificates\Root\ProtectedRoots" -ValueName "PeerUsages" -errorAction SilentlyContinue).value -match "1.3.6.1.5.5.7.3.2 1.3.6.1.5.5.7.3.4 1.3.6.1.4.1.311.10.3.4") {
                                return $True
                                }
                            else {
                                return $False
                                }
                        }
            SetScript = {
                            Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\SystemCertificates\Root\ProtectedRoots" -ValueName "PeerUsages" -value "1.3.6.1.5.5.7.3.2", "1.3.6.1.5.5.7.3.4", "1.3.6.1.4.1.311.10.3.4" -Type String
                        }
            GetScript = {
                            $RegVal3 = (Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\SystemCertiticates\Root\ProtectedRoots" -ValueName "PeerUsages")
                            return @{Result = $RegVal3}
                        }
            DependsOn = '[Script]setAEGPRegSetting3'
        }

        Script SetAEGPLink
        {
            Credential = $EACredential
            TestScript = {
                            if (([xml](Get-GPOReport -Name "PKI AutoEnroll" -ReportType XML)).GPO.LinksTo.SOMPath -match $Using:Node.Domain) {
                                write-output "Group policy PKI Autoenroll already linked to domain."
                                return $True
                                }
                            else {
                                write-output "Group policy PKI Autoenroll not linked at domain level."
                                return $False
                                }
                        }
            SetScript = {
                            New-GPLink -name "PKI AutoEnroll" -Target $Using:Node.DomainDN -LinkEnabled Yes 
                        }
            GetScript = {
                            $GPLink = set-GPLink -name "PKI AutoEnroll" -target $Using:Node.DomainDN
                            return @{Result = $GPLink}
                        }
            DependsOn = '[Script]setAEGPRegSetting4'
        }                           

#end region - Add GPO for PKI AutoEnroll

#region - ADCS
                            
        WindowsFeature ADCS
        {
            Ensure = "Present"
            Name = "ADCS-Cert-Authority"
            DependsOn = '[xADDomain]FirstDC'
        }

        xAdcsCertificationAuthority ADCSConfig
        {
            CAType = 'EnterpriseRootCA'
            Credential = $EACredential
            CryptoProviderName = 'RSA#Microsoft Software Key Storage Provider'
            HashAlgorithmName = 'SHA256'
            KeyLength = 2048
            CACommonName = $Node.CACN
            CADistinguishedNameSuffix = $Node.CADNSuffix
            DatabaseDirectory = $Node.CADatabasePath
            LogDirectory = $Node.CALogPath
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 2
            DependsOn = '[WindowsFeature]ADCS','[xADDomain]FirstDC'    
        }

#Note:  The Test section is pure laziness.  Future enhancement:  test for more than just existence.
        script CreateWebServer2Template
        {
            DependsOn = '[xAdcsCertificationAuthority]ADCSConfig'
            Credential = $EACredential
            TestScript = {
                            try {
                                $WSTemplate=get-ADObject -Identity "CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -Properties * -ErrorAction Stop
                                return $True
                                }
                            catch {
                                return $False
                                }
                         }
            SetScript = {
                         $WebServerTemplate = @{'flags'='131649';
                        'msPKI-Cert-Template-OID'='1.3.6.1.4.1.311.21.8.8211880.1779723.5195193.12600017.10487781.44.7319704.6725493';
                        'msPKI-Certificate-Application-Policy'='1.3.6.1.5.5.7.3.1';
                        'msPKI-Certificate-Name-Flag'='268435456';
                        'msPKI-Enrollment-Flag'='32';
                        'msPKI-Minimal-Key-Size'='2048';
                        'msPKI-Private-Key-Flag'='50659328';
                        'msPKI-RA-Signature'='0';
                        'msPKI-Supersede-Templates'='WebServer';
                        'msPKI-Template-Minor-Revision'='3';
                        'msPKI-Template-Schema-Version'='2';
                        'pKICriticalExtensions'='2.5.29.15';
                        'pKIDefaultCSPs'='2,Microsoft DH SChannel Cryptographic Provider','1,Microsoft RSA SChannel Cryptographic Provider';
                        'pKIDefaultKeySpec'='1';
                        'pKIExtendedKeyUsage'='1.3.6.1.5.5.7.3.1';
                        'pKIMaxIssuingDepth'='0';
                        'revision'='100'}


                        New-ADObject -name "WebServer2" -Type pKICertificateTemplate -Path "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -DisplayName WebServer2 -OtherAttributes $WebServerTemplate
                        $WSOrig = Get-ADObject -Identity "CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -Properties * | Select-Object pkiExpirationPeriod,pkiOverlapPeriod,pkiKeyUsage
                        Get-ADObject -Identity "CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" | Set-ADObject -Add @{'pKIKeyUsage'=$WSOrig.pKIKeyUsage;'pKIExpirationPeriod'=$WSOrig.pKIExpirationPeriod;'pkiOverlapPeriod'=$WSOrig.pKIOverlapPeriod}
                        }
                GetScript = {
                                try {
                                    return {get-ADObject -Identity "CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -Properties * -ErrorAction Stop}
                                    }
                                catch {
                                    return @{Result=$Null}
                                    }
                            }
        }
         
        script PublishWebServerTemplate2 
        {       
           DependsOn = '[Script]CreateWebServer2Template'
           Credential = $EACredential
           TestScript = {
                            $Template= Get-CATemplate | Where-Object {$_.Name -match "WebServer2"}
                            if ($Template -eq $Null) {return $False}
                            else {return $True}
                        }
           SetScript = {
                            add-CATemplate -name "WebServer2" -force
                        }
           GetScript = {
                            return {Get-CATemplate | Where-Object {$_.Name -match "WebServer2"}}
                        }
         }
                                                     

#end region - ADCS

#would like to collapse next two into one resource with a foreach loop on the GUIDs, but can't get it working.

        script SetWebServerTemplateAutoenroll
        {
            DependsOn = '[Script]CreateWebServer2Template'
            Credential = $EACredential
            TestScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
                if ($WebServerCertACL -eq $Null) {
                    write-verbose "Web Servers Group does not have permissions on Web Server template"
                    Return $False
                    }
                elseif (($WebServerCertACL.ActiveDirectoryRights -like "*ExtendedRight*") -and ($WebServerCertACL.ObjectType -notcontains "a05b8cc2-17bc-4802-a710-e7c15ab866a2")) {
                    write-verbose "Web Servers group has permission, but not the correct permission."
                    Return $False
                    }
                else {
                    write-verbose "ACL on Web Server Template is set correctly for this GUID for Web Servers Group"
                    Return $True
                    }
                }
             SetScript = {
                Import-Module activedirectory
                $WebServersGroup = get-adgroup -Identity "Web Servers" | Select-Object SID
                $EnrollGUID = [GUID]::Parse("a05b8cc2-17bc-4802-a710-e7c15ab866a2")
                $ACL = get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
                set-ACL "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
                write-verbose "AutoEnroll permissions set for Web Servers Group"
                }
             GetScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
                if ($WebServerCertACL -ne $Null) {
                    return $WebServerCertACL
                    }
                else {
                    Return @{}
                    }
                }
         }
            
    script SetWebServerTemplateEnroll
        {
            DependsOn = '[Script]CreateWebServer2Template'
            Credential = $EACredential
            TestScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
                if ($WebServerCertACL -eq $Null) {
                    write-verbose "Web Servers Group does not have permissions on Web Server template"
                    Return $False
                    }
                elseif (($WebServerCertACL.ActiveDirectoryRights -like "*ExtendedRight*") -and ($WebServerCertACL.ObjectType -notcontains "0e10c968-78fb-11d2-90d4-00c04f79dc55")) {
                    write-verbose "Web Servers group has permission, but not the correct permission."
                    Return $False
                    }
                else {
                    write-verbose "ACL on Web Server Template is set correctly for this GUID for Web Servers Group"
                    Return $True
                    }
                }
             SetScript = {
                Import-Module activedirectory
                $WebServersGroup = get-adgroup -Identity "Web Servers" | Select-Object SID
                $EnrollGUID = [GUID]::Parse("0e10c968-78fb-11d2-90d4-00c04f79dc55")
                $ACL = get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
                set-ACL "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
                write-verbose "Enroll permissions set for Web Servers Group"
                }
             GetScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer2,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
                if ($WebServerCertACL -ne $Null) {
                    return $WebServerCertACL
                    }
                else {
                    Return @{}
                    }
                }
         }
    }

    node $AllNodes.where{$_.Role -eq "PullServer"}.NodeName {  

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

LabInfraBuild -configurationData $ConfigData -outputpath "C:\DSC\Config" -EACredential (get-credential -username "blah.com\administrator" -Message "EA for ADCS/checking domain presence") -SafeModeAdminPW (get-credential -Username 'Password Only' -Message "Safe Mode Admin PW")
