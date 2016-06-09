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
    [pscredential]$DACredential,

    [parameter(Mandatory=$True)]
    [pscredential]$SafeModeAdminPW
    )

    import-DSCresource -ModuleName PSDesiredStateConfiguration,@{ModuleName="xActiveDirectory";ModuleVersion="2.11.0.0"}

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
            DomainAdministratorCredential = $DACredential
            SafemodeAdministratorPassword = $SafeModeAdminPW
            DatabasePath = $Node.DCDatabasePath
            LogPath = $Node.DCLogPath
            SysvolPath = $Node.SysvolPath 
            DependsOn = '[WindowsFeature]ADDS'
        }         
    }
}

LabInfraBuild -configurationData $ConfigData -outputpath "C:\DSC\Config" -DACredential (get-credential -username "blah.com\administrator" -Message "DA for checking domain presence") -SafeModeAdminPW (get-credential -Username 'Password Only' -Message "Safe Mode Admin PW")