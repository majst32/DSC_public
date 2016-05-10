# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.    
    Absent
    # The resource must be present.    
    Present
}

# [DscResource()] indicates the class is a DSC resource.
[DscResource()]
class mDHCPFailover2
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$RelationshipName

    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Mandatory)]
    [string] $ScopeName

    [DscProperty(Mandatory)]
    [string] $PartnerServer

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DSCProperty()]
    [bool] $AutoStateTransition

    [DSCProperty()]
    [string] $SharedSecret

    [DSCProperty()]
    [string] $MCLT

    [DSCProperty()]
    [int] $LBPercentage

    [DSCProperty()]
    [string] $StateSwitchInterval
 
 
    
    # Sets the desired state of the resource.
    [void] Set()
    {  
        
        #########################################Fix input types

    #shamelessly stolen from helper function, handle later :S

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($This.MCLT, [ref]$timeSpan)

    $This.MCLT=$timeSpan

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($This.StateSwitchInterval, [ref]$timeSpan)

    $This.StateSwitchInterval=$timeSpan

    ############################End fix input#############################################

    If ($This.Ensure -match "Absent") {
        write-verbose "Removing DHCP failover relationship"
        Remove-DhcpServerv4Failover -Name $This.RelationshipName
        write-verbose "DHCP Failover relationship removed successfully"
        }
    else {
        try {
            $null = Get-DhcpServerv4Failover -ScopeId $This.ScopeName -ErrorAction Stop
            write-verbose "Modifying DHCP failover relationship $($This.RelationshipName)"
            Set-DhcpServerv4Failover -Name $This.RelationshipName -SharedSecret $This.SharedSecret -AutoStateTransition $This.AutoStateTransition -MaxClientLeadTime $This.MCLT -StateSwitchInterval $This.StateSwitchInterval -LoadBalancePercent $This.LBPercentage
            Write-Verbose "DHCP failover relationship modified successfully"
            }
        catch {
            write-verbose "Adding DHCP failover relationship"
            Add-DhcpServerv4Failover -Name $This.RelationshipName -PartnerServer $This.PartnerServer -ScopeId $This.ScopeName -SharedSecret $This.SharedSecret -MaxClientLeadTime $This.MCLT -StateSwitchInterval $This.StateSwitchInterval
            write-verbose "DHCP failover relationship created"
            }
        }

    }
                
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
    #########################################Fix input types

    #shamelessly stolen from helper function, handle later :S

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($This.MCLT, [ref]$timeSpan)

    $This.MCLT=$timeSpan

    [System.TimeSpan]$timeSpan = New-TimeSpan
    $result = [System.TimeSpan]::TryParse($This.StateSwitchInterval, [ref]$timeSpan)

    $This.StateSwitchInterval=$timeSpan

        #Write-Verbose "Use this cmdlet to deliver information about command processing."

        #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

         try {
            $testFailover = Get-DhcpServerv4Failover -ScopeId $This.ScopeName -ErrorAction Stop
            }
        catch {  #If currently absent, will fall into catch
            if ($This.Ensure -match 'Present') {
                write-verbose "Failover relationship not present, configuration is needed."
                return $False
            }
            else {
                write-verbose "Failover relationship is not present, already in desired state."
                return $True
            }
        }
        #If currently present, check if absent is desired state
        if ($This.Ensure -match 'Absent') {
            write-verbose "Failover relationship is configured, desired state is unconfigured."
            return $False
            }
        
        #Otherwise failover is currently present and desired present, so check all settings.        
        elseif ($TestFailover.Name -notmatch $This.RelationshipName) {
            write-verbose "Failover Name does not match $($This.RelationshipName), configuration is needed."
            return $False
            }
        elseif ($TestFailover.PartnerServer -notmatch $This.PartnerServer) {
            write-verbose "Failover relationship with $($This.PartnerServer) is not found, configuration is needed."
            return $False
            }
        elseif ($TestFailover.AutoStateTransition -ne $This.AutoStateTransition) {
            Write-Verbose "Failover Auto State Transition does not match $($This.AutoStateTranstion), configuration is needed."
            return $False
            }
    
        #Cannot test SharedSecret - get-DHCPServerv4Failover does not return this value
        #More research is needed to see if it can be checked some other way
        #Skip checking for now
        <#
        elseif ($TestFailover.SharedSecret -notmatch $SharedSecret) {
            Write-Verbose "Shared Secret does not match desired shared secret, configuration is needed."
            return $False
            }  #>


         elseif (($This.MCLT -ne $Null) -and ($TestFailover.MaxClientLeadTime -ne $This.MCLT)) {  #Only check if a value is specified
            Write-Verbose "$($TestFailover.MaxClientLeadTime) does not match $($This.MCLT)."
            return $False
            }
        elseif (($This.LBPercentage -ne $Null) -and ($TestFailover.LoadBalancePercent -ne $This.LBPercentage)) { #Only check if a value is specified
            Write-Verbose "Load Balancing Percentage does not match $($This.LBPercentage) Percent."
            return $False
            }
        elseif (($This.StateSwitchInterval -ne $Null) -and ($TestFailover.StateSwitchInterval -notmatch $This.StateSwitchInterval)) { #Only check if a value is specified
            Write-Verbose "State Switch Interval does not match $($This.StateSwitchInterval)"
            return $False
            }
        else {
            Write-Verbose "All settings configured as requested."
            return $True
            }
    }
  
       
     # Gets the resource's current state.
     [mDHCPFailover2] Get()
     {        
        $relationship = Get-DhcpServerv4Failover -erroraction silentlyContinue | Where-Object {$_.PartnerServer -match $PartnerServer}

        if ($relationship.Name -match "*$($This).RelationshipName*") {
            Write-Verbose "Failover relationship exists."
        }
        else {
            Write-Verbose "Failover relationship does not exist, not in desired state."
            $this = $null
        }
        return $this 
    }    
}