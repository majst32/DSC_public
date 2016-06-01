function Get-VMSwitchName {
<#
.SYNOPSIS
Checks the current Hyper-V environment to see if there is a switch of the specified type.  Returns the switch name if one exists.  Creates one if it does not.
.DESCRIPTION
Checks the current Hyper-V environment to see if there is a switch of the specified type.  Returns the switch name if one exists.  Creates one if it does not.
.PARAMETER SwitchType
Must be one of the three valid switch types - "Internal", "External", or "Private".
.EXAMPLES
get-VMSwitchName -SwitchType External -verbose
get-VMSwitchName -SwitchType Private
.NOTES
Author - Melissa Januszko [mj] 6/1/16
#>

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')]   
    
    param (
        [parameter(Mandatory=$True)]
        [validateSet("Internal","External","Private")]
        $SwitchType
        )

$SwitchName = (Get-VMSwitch).where{$_.SwitchType -eq $SwitchType} | Select-Object -ExpandProperty Name
If ($SwitchName -ne $Null) {
    write-verbose "$($SwitchName) exists, skipping creation."
    return $SwitchName
    }

if ($SwitchName -eq $Null) {
    if ($SwitchType -eq "External") {
        $Null = New-VMSwitch -AllowManagementOS $true -NetAdapterName "Wi-Fi" -name "External Switch"
        $SwitchName = get-VMSwitch -SwitchType External | Select-Object -expandproperty Name
        write-verbose "New External Switch named $($SwitchName) created."
        }
    else {
        $Null = New-VMSwitch -Name "$($SwitchType) Switch" -SwitchType $SwitchType
        $SwitchName = Get-VMSwitch -SwitchType $SwitchType | select-object -ExpandProperty Name
        Write-Verbose "New $($SwitchType) Switch named $($SwitchName) created."
        }
    }
return $SwitchName
}

function Start-VMImage {
<#
.SYNOPSIS
Starts the VM specified.
.DESCRIPTION
Starts the VM if it is not started and the VHDX file exists.
.PARAMETER VHDXPath
Full path to VHDX file to start.
.PARAMETER VMName
Name of VM to start.
.EXAMPLES
start-VMImage -VHDXPath ".\GoldImage\Windows 2012 R2 Gold Image.vhdx" -VMName "2012R2Gold"
start-VMImage -VHDXPath ".\DC.vhdx" -VMName DC
.NOTES
Author - Melissa Januszko [mj] 6/1/16
#>

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')] 

    param (
        [string] $VHDXPath,
        [string] $VMName
        )

    if (-not (Test-Path -Path $VHDXPath)) {
        Write-Verbose "Gold Image file $($VHDXPath) does not exist."
        exit
        }

    #check if VM exists - create if it doesn't - turn on if off
    $VM = Get-VM -Name $VMName -ErrorAction Stop
    if ($Vm.State -eq "Off") {
    Write-Verbose "$VMName VM is currently turned off.  Starting VM."
    start-VM -Name $VMName
    Write-Verbose "$VMName has been started."
        }    
    else 
        {
        Write-Verbose "$VMName VM is already running, no action is necessary."
        }   
    }

function add-VMImage {
<#
.SYNOPSIS
Creates a VM from a VHDX file.
.DESCRIPTION
Creates a new VM from a VHDX file.
.PARAMETER SwitchName
Name of switch to attach the VM..
.PARAMETER VHDXPath
Path to VHDX file.
.PARAMETER VMName
Name of VM to create.
.PARAMETER 
.EXAMPLES
.NOTES
Author - Melissa Januszko [mj] 6/1/16
#>

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')] 

    param (
        [parameter(Mandatory=$True)]
        [string]$SwitchName,
        [parameter(Mandatory=$True)]
        [string]$VHDXPath,
        [parameter(Mandatory=$True)]
        [string]$VMName
        )

    write-verbose "Creating new VM $($VMName)."
    $Null = New-VM -name $VMName -MemoryStartupBytes 1GB -BootDevice VHD -VHDPath $VHDXPath -SwitchName $SwitchName
}




