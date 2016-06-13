﻿$ConfigData = @{
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
                    PSDCSAllowDomainUser = $True
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

    import-DSCresource -ModuleName PSDesiredStateConfiguration,@{ModuleName="xActiveDirectory";ModuleVersion="2.11.0.0"},@{ModuleName="XADCSDeployment";ModuleVersion="1.0.0.0"}

    node $AllNodes.NodeName
    {
       
        WindowsFeature ServerCore
        {
            Ensure = "Absent"
            Name = "User-Interfaces-Infra"
            IncludeAllSubFeature = $True
        } 
    }
    
    node $AllNodes.Where{$_.Role -eq "AD_ADCS"}.NodeName {
        
        WindowsFeature ADDS
        {
           Ensure = "Present"
           Name   = "AD-Domain-Services"
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
        
        xAdcsCertificationAuthority ADCS
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
            DependsOn = '[xADDomain]FirstDC'    
        }
    }
}

LabInfraBuild -configurationData $ConfigData -outputpath "C:\DSC\Config" -EACredential (get-credential -username "blah.com\administrator" -Message "EA for ADCS/checking domain presence") -SafeModeAdminPW (get-credential -Username 'Password Only' -Message "Safe Mode Admin PW")