$ConfigData=@{
    AllNodes = 
    @(
        @{
            NodeName  = "*"
        },
        @{
            NodeName = "S1";
            Role     = "TestConfig"
        }     
    )  
}

configuration TestConfig
{
  
    Import-DscResource -ModuleName PSDesiredStateConfiguration 
    node $AllNodes.Where{$_.Role -eq "TestConfig"}.Role
    {
        WindowsFeature WindowsBackup
        {
            Name   = 'Windows-Server-Backup'
            Ensure = 'Present'
        }
    }
}

TestConfig -ConfigurationData $ConfigData -OutputPath "C:\DSC\Config"