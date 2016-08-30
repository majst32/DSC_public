[cmdletbinding()]
param()

#### All setup

$Props = @{'Ensure'="Present";
        'Scope'="192.168.2.0"; 
        'RelationshipName'="LBFailoverConfig";
        'PartnerServer'="S3";
        'AutoStateTransition'=$True;
        'LBPercentage'=50;
        'MCLT'='02:00:00';
        'StateSwitchInterval'="02:00:00"}
        #'SharedSecret'="whatever"} 


$This = new-object -TypeName PSObject -Property $Props

#shamelessly stolen from helper function, handle later :S

[System.TimeSpan]$timeSpan = New-TimeSpan
$result = [System.TimeSpan]::TryParse($This.MCLT, [ref]$timeSpan)

<#if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidTimeSpanFormat) -f $parameterName
        New-TerminatingError -errorId 'NotValidTimeSpan' -errorMessage $errorMsg -errorCategory InvalidType
    }#>

$This.MCLT=$timeSpan

[System.TimeSpan]$timeSpan = New-TimeSpan
$result = [System.TimeSpan]::TryParse($This.StateSwitchInterval, [ref]$timeSpan)

<#if(-not $result)
    {
        $errorMsg = $($LocalizedData.InvalidTimeSpanFormat) -f $parameterName
        New-TerminatingError -errorId 'NotValidTimeSpan' -errorMessage $errorMsg -errorCategory InvalidType
    }#>

$This.StateSwitchInterval=$timeSpan

$ComputerName = "S2"

####End setup

    try {
        $testFailover = Get-DhcpServerv4Failover -ComputerName $ComputerName -ScopeId $this.Scope -ErrorAction Stop
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
    elseif ($TestFailover.SharedSecret -notmatch $This.SharedSecret) {
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
        
   