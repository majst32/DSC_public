<#
.SYNOPSIS
Creates new vhdx file copied from Image specified, adds the server to Hyper-V, and boots it.
.DESCRIPTION
Creates new vhdx file copied from Image specified, adds the server to Hyper-V, and boots it.  
A VHDX of the same name will be deleted and recreated from the image.
.PARAMETER InitialImage
Path to the "Gold Image" or other VHDX file to copy.
.PARAMETER VHDXPath
Path to the new server's VHDX.
.PARAMETER VMName
Name of server in Hyper-V
.PARAMETER SwitchType
Type of switch for new server to be attached to
.EXAMPLES
.\Create-newVMFromImage -InitialImage "C:\HyperV\GoldImage\2012.vhdx" -VHDXPath "C:\HyperV\VM\DC1.vhdx" -SwitchType Internal -verbose
.NOTES
Author - Melissa Januszko [mj] 6/1/16
#>

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')] 
param (
    [parameter(Mandatory=$True)]
    [string] $InitialImage,
    [parameter(Mandatory=$True)]
    [string] $VHDXPath,
    [parameter(Mandatory=$True)]
    [string] $VMName,
    [parameter(Mandatory=$True)]
        [validateSet("Internal","External","Private")]
        $SwitchType
    )

import-module VMManagement

$SwitchName = Get-VMSwitchName -SwitchType $SwitchType
$Status = get-VM -name $VMName -erroraction SilentlyContinue

#If server is currently running, do nothing and exit.
if (($Status -ne $Null) -and ($Status.State -eq "Running")) {
    Write-Verbose "$VMName already exists and is currently running.  Shut down the VM and re-run script."
    exit
    }

#If server exists but is not currently running, delete it.
if (($Status -ne $Null) -and ($Status.State -ne "Running")) {
    remove-VM -name $VMName -Force
    write-verbose "Removing VM $VMName from Hyper-V."
    }

#check that build file exists
if (-not (Test-Path -Path $InitialImage)) {
    write-verbose "Build file does not exist."
    exit
    }

#check that output file does not exist - delete existing if exists
if (Test-Path -Path $VHDXPath) {
    Write-Verbose "VHDX file $($VHDXPath) already exists, deleting to recreate."
    remove-item -Path $VHDXPath -Force
    }

copy-item -path $InitialImage -Destination $VHDXPath
Add-VMImage -switchName $SwitchName -VHDXPath $VHDXPath -VMName $VMName -verbose
Start-VMImage -VHDXPath $VHDXPath -VMName $VMName -verbose
