$ConfigData = @{
                AllNodes = @(
                @{
                    NodeName = "*"
                    Domain = "blah.com"
                    DCDatabasePath = "C:\NTDS"
                    DCLogPath = "C:\NTDS"
                    SysvolPath = "C:\Sysvol" 
                },
                @{
                    NodeName = "DC1"
                    Role = "AD_ADCS"
                    PSDSCAllowPlainTextPassword = $True
                    PSDSCAllowDomainUser = $True
                    DomainDN = "dc=blah,dc=com"
                },
                @{
                    NodeName = "Pull"
                    Role = "PullServer"
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

    import-DSCresource -ModuleName PSDesiredStateConfiguration,@{ModuleName="xActiveDirectory";ModuleVersion="2.11.0.0"},@{ModuleName="XADCSDeployment";ModuleVersion="1.0.0.1"}

    node $AllNodes.NodeName
    {
       
        WindowsFeature ServerCore
        {
            Ensure = "Absent"
            Name = "User-Interfaces-Infra"
            IncludeAllSubFeature = $false
        } 
    }
    
    node $AllNodes.Where{$_.Role -eq "AD_ADCS"}.NodeName {
        
        WindowsFeature ADDS
        {
           Ensure = "Present"
           Name   = "AD-Domain-Services"
        }

        WindowsFeature GPMC
        {
            Ensure = 'Present'
            Name = 'GPMC'
        }
        
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

         xADOrganizationalUnit GroupsOU
        {
            Name = 'Groups'
            Path = 'DC=blah,DC=com'
            DependsOn = '[xADDomain]FirstDC'
            Ensure = 'Present'
            ProtectedFromAccidentalDeletion = $True
            Credential = $EaCredential
        }

         xADGroup WebServerGroup
        {
            GroupName = 'Web Servers'
            GroupScope = 'Global'
            DependsOn = '[xADOrganizationalUnit]GroupsOU'
            #Members = $AllNodes.Where{$_.Role -eq "PullServer"}.NodeName
            Credential = $EACredential
            Category = 'Security'
            Path = "OU=Groups,DC=blah,DC=com"
            Ensure = 'Present'
        }

        script CreatePKIAEGpo
        {
            Credential = $EACredential
            TestScript = 'if ((get-gpo -name "PKI AutoEnroll" -ErrorAction SilentlyContinue) -eq $Null) {
                            write-verbose "PKI AutoEnroll Policy does not exist."
                            return $False
                            } 
                          else {
                          write-verbose "PKI AutoEnroll policy alreaady exists."
                          return $True}'
            SetScript = 'new-gpo -name "PKI AutoEnroll"'
            GetScript = 'return (get-gpo -name "PKI AutoEnroll")'
            DependsOn = '[xADDomain]FirstDC'
        }
        
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
            CACommonName = "blahblahblah root"
            CADistinguishedNameSuffix = "C=US,L=Somecity,S=Pennsylvania,O=Test Corp"
            DatabaseDirectory = 'C:\windows\system32\CertLog'
            LogDirectory = 'C:\CA_Logs'
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 2
            DependsOn = '[WindowsFeature]ADCS','[xADDomain]FirstDC'    
        }
    }
}

LabInfraBuild -configurationData $ConfigData -outputpath "C:\DSC\Config" -EACredential (get-credential -username "blah.com\administrator" -Message "EA for ADCS/checking domain presence") -SafeModeAdminPW (get-credential -Username 'Password Only' -Message "Safe Mode Admin PW")
