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
                    PSDSCAllowPlainTextPassword = $True
                    PSDSCAllowDomainUser = $True
                    DNSServerIP = '192.168.2.11'
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
        @{ModuleName="xComputerManagement";ModuleVersion="1.6.0.0"}
    
    node $AllNodes.NodeName
    {
       
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
            DependsOn = '[xFirewall]RemoteEvtLogFWRule3'
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
            DependsOn = '[xFirewall]vmpingFWRule','[xFirewall]SMB','[xFirewall]RemoteEvtLogFWRule1','[xFirewall]RemoteEvtLogFWRule2','[xFirewall]RemoteEvtLogFWRule3'
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

#Add Web Servers group - add pull server as member later

         xADGroup WebServerGroup
        {
            GroupName = 'Web Servers'
            GroupScope = 'Global'
            DependsOn = '[xADOrganizationalUnit]GroupsOU'
            #Members = $AllNodes.Where{$_.Role -eq "PullServer"}.NodeName
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
      
        Script SetAEGPLink
        {
            Credential = $EACredential
            TestScript = {
                            try {
                                    set-GPLink -name "PKI AutoEnroll" -target $Using:Node.DomainDN -LinkEnabled Yes -ErrorAction silentlyContinue
                                    return $True
                                }
                            catch
                                {
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
            DependsOn = '[Script]setAEGPRegSetting3'
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


#end region - ADCS

#would like to collapse next two into one resource with a foreach loop on the GUIDs, but can't get it working.

        script SetWebServerTemplateAutoenroll
        {
            DependsOn = '[xAdcsCertificationAuthority]ADCSConfig'
            Credential = $EACredential
            TestScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
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
                $ACL = get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
                set-ACL "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
                write-verbose "AutoEnroll permissions set for Web Servers Group"
                }
             GetScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
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
            DependsOn = '[xAdcsCertificationAuthority]ADCSConfig'
            Credential = $EACredential
            TestScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
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
                $ACL = get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
                $ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
                #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
                set-ACL "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
                write-verbose "Enroll permissions set for Web Servers Group"
                }
             GetScript = {
                Import-Module activedirectory
                $WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
                if ($WebServerCertACL -ne $Null) {
                    return $WebServerCertACL
                    }
                else {
                    Return @{}
                    }
                }
         }

    }

    

    node $AllNodes.Where{$_.Role -eq "PullServer"}.NodeName {

        xDNSServerAddress SetDNSServer
        {
            Address = $Node.DNSServerIP
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
        }
        
        xWaitForADDomain WaitforAD
        {
            DomainName = $Node.Domain
            RetryIntervalSec = 60
            RetryCount = 30
        } 

        xComputer JoinPullToDomain
        {
            Name = $Node.NodeName
            DomainName = $Node.Domain
            DependsOn = '[xWaitForADDomain]WaitforAD'
            JoinOU = $Node.ServersOU
            Credential = $EACredential
        }

     }   
}

LabInfraBuild -configurationData $ConfigData -outputpath "C:\DSC\Config" -EACredential (get-credential -username "blah.com\administrator" -Message "EA for ADCS/checking domain presence") -SafeModeAdminPW (get-credential -Username 'Password Only' -Message "Safe Mode Admin PW")
