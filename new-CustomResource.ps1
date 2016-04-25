new-xDscResource -Name mDHCPFailoverScope -ModuleName mDHCPFailover -path "C:\Program Files\WindowsPowershell\Modules" -property $(
    New-xDscResourceProperty -Name "RelationshipName" -Type String -Attribute Key
    New-xDscResourceProperty -Name "Mode" -Type String -attribute Write -ValidateSet ("LoadBalancing","HotStandby")
    #NOTE, this won't work, should be of type IPAddress, only here for practice purposes as string
    New-xDscResourceProperty -Name "Scope" -Type String -Attribute Write
    New-xDscResourceProperty -Name "PartnerServer" -type string -Attribute Write
    New-xDscResourceProperty -Name "AutoStateTransition" -type Boolean -Attribute Write
    #NOTE, can you treat this as a credential?
    New-xDscResourceProperty -Name "SharedSecret" -type string -Attribute Write
    #NOTE, what about types of DateTime vs Timespan? 
    New-xDscResourceProperty -Name "MCLT" -type DateTime -Attribute Write
    New-xDscResourceProperty -Name "LBPercentage" -Type Uint32 -Attribute Write
    New-xDscResourceProperty -Name "ReservePercent" -type Uint32 -Attribute Write
    New-xDscResourceProperty -Name "ServerRole" -type String -Attribute Write
    #NOTE, same with DateTime vs Timespan
    New-xDscResourceProperty -Name "StateSwitchInterval" -type DateTime -Attribute Write
    )