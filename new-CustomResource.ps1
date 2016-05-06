new-xDscResource -Name mDHCPFailoverRelationship -ModuleName mDHCPFailover -path "C:\Program Files\WindowsPowershell\Modules" -property $(
    New-xDscResourceProperty -Name "Ensure" -type String -Attribute Required -validateSet Present,Absent
    New-xDscResourceProperty -Name "RelationshipName" -Type String -Attribute Key
    New-xDscResourceProperty -Name "ScopeName" -Type String -Attribute Required
    New-xDscResourceProperty -Name "PartnerServer" -type string -Attribute Required
    New-xDscResourceProperty -Name "AutoStateTransition" -type Boolean -Attribute Write
    #NOTE, can you treat this as a credential?
    New-xDscResourceProperty -Name "SharedSecret" -type string -Attribute Write
    New-xDscResourceProperty -Name "MCLT" -type string -Attribute Write
    New-xDscResourceProperty -Name "LBPercentage" -Type Uint32 -Attribute Write
    New-xDscResourceProperty -Name "StateSwitchInterval" -type string -Attribute Write
    )
<#
new-xDscResource -Name mDHCPHSFailoverRelationship -ModuleName mDHCPFailover -path "C:\Program Files\WindowsPowershell\Modules" -property $(
    New-xDscResourceProperty -Name "Ensure" -type String -Attribute Write -validateSet Present,Absent
    New-xDscResourceProperty -Name "RelationshipName" -Type String -Attribute Key
    New-xDscResourceProperty -Name "Scope" -Type String -Attribute Key
    New-xDscResourceProperty -Name "PartnerServer" -type string -Attribute Required
    New-xDscResourceProperty -Name "AutoStateTransition" -type Boolean -Attribute Write
    #NOTE, can you treat this as a credential?
    New-xDscResourceProperty -Name "SharedSecret" -type string -Attribute Write
    #NOTE, what about types of DateTime vs Timespan? 
    New-xDscResourceProperty -Name "MCLT" -type String -Attribute Write
    New-xDscResourceProperty -Name "ReservePercent" -type Uint32 -Attribute Write
    New-xDscResourceProperty -Name "ServerRole" -type String -Attribute Write
    #NOTE, same with DateTime vs Timespan
    New-xDscResourceProperty -Name "StateSwitchInterval" -type String -Attribute Write
    )
#>