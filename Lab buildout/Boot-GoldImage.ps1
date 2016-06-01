<#
.SYNOPSIS
Boots the specified "Gold Image" Server if it exists in Hyper-V.  Adds the VM and boots it if it does not exist in Hyper-V.
.DESCRIPTION
Boots the specified "Gold Image" Server if it exists in Hyper-V.  Adds the VM and boots it if it does not exist in Hyper-V.
.PARAMETER GIPath
Path to the "Gold Image" VHDX file.
.PARAMETER ImageName
VM Name in Hyper-V.
.EXAMPLES
.\Boot-GoldImage -GIPath "C:\HyperV\GoldImage\2012.vhdx" -ImageName "2012Gold" -verbose
.NOTES
Author - Melissa Januszko [mj] 6/1/16
#>

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')] 

param (
    [string] $GIPath,
    [string] $ImageName
    )

import-module VMManagement

$SwitchName = Get-VMSwitchName -SwitchType External

if (-not (Test-Path -Path $GIPath)) {
    Write-Verbose "Gold Image file $($GIPath) does not exist."
    exit
    }

#check if VM exists - create if it doesn't - turn on if off
try {
        Start-VMImage -VHDXPath $GIPath -VMName $ImageName -verbose
    }
catch {
        Add-VMImage -switchName $SwitchName -VHDXPath $GIPath -VMName $ImageName -verbose
        Start-VMImage -VHDXPath $GIPath -VMName $ImageName -verbose
    }


