 $ConfigData=@{
    AllNodes = @(
        @{
            NodeName  = "*"
            WSUSUrl = "http://w2:8530"

        },
        @{
            NodeName = 'S1'
            GUID = Get-DscLocalConfigurationManager -CimSession S1 | Select-Object -ExpandProperty ConfigurationID
        },
        @{
            NodeName = 'S2'
            Role     = @('DHCPServer','DHCPServer1')
            GUID = Get-DscLocalConfigurationManager -CimSession S2 | Select-Object -ExpandProperty ConfigurationID
            Partner = "S3"
        }, 
        @{
            NodeName = 'S3'
            Role     = 'DHCPServer'
            GUID = Get-DscLocalConfigurationManager -CimSession S3 | Select-Object -ExpandProperty ConfigurationID
        } 

    );
}
  
configuration BuildOut {
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xDHCPServer,CompositeDSC,@{moduleName="mDHCPFailover";moduleVersion="1.1"}
    
    node $AllNodes.GUID {
        
        BaseConfig Base {
            WSUSURL = '$Node.WSUSUrl'
        }
           

#####After setting all the registry settings, need to recycle wuauserv, how do you do this?
#####Can't set it to stopped and then started with a DSC resource :(
#####Then need it to install patches########################################################

#########################################END WSUS###########################################
    
#End Node     
    }

    node $AllNodes.Where{$_.Role -eq 'DHCPServer'}.GUID {

###########################################START DHCP####################################
#Should statically assign IP address first
#Should set WSUS and update after
#########################################################################################

    WindowsFeature DHCP {
        Name = 'DHCP'
        Ensure = 'Present'
    }

    WindowsFeature DHCPMgmt {
        Name = 'RSAT-DHCP'
        Ensure =  'Present'
    }

    #Add DHCP service Present/Running here

   }

node $AllNodes.Where{$_.Role -eq 'DHCPServer1'}.GUID {

    xDHCPServerScope TestScope {
        IPEndRange = '192.168.2.254'
        IPStartRange = '192.168.2.1'
        Name = 'TestScope'
        SubnetMask = '255.255.255.0'
        AddressFamily = 'IPv4'
        DependsOn = '[WindowsFeature]DHCP'
        Ensure = 'Present'
        LeaseDuration = '10'
        State = 'Inactive'
    }


    mDHCPFailoverRelationship fakeVLANScopeFailover {

    Ensure = 'Present'
    PartnerServer = 'S3'
    RelationshipName = 'LBFailover'
    ScopeName = '192.168.2.0'
    DependsOn = '[xDhcpServerScope]TestScope'
    LBPercentage = 50
    SharedSecret = 'blahblahblah'
    
    }

}

################Need cross-machine dependency for DHCP to be installed on both servers####

###########################################END DHCP####################################

 
}

BuildOut -ConfigurationData $ConfigData -OutputPath "C:\DSC\Config"
