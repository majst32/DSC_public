$InitialImage = "D:\MissyHyperV\Gold Image\Windows 2012 R2 Gold Image.vhdx"
$switch = "Private"
.\Create-newVMFromImage.ps1 -InitialImage $InitialImage -VHDXPath "C:\HyperV\VMs\DC1.vhdx" -VMName DC1 -SwitchType $switch
.\Create-newVMFromImage.ps1 -InitialImage $InitialImage -VHDXPath "C:\HyperV\VMs\Pull.vhdx" -VMName Pull -SwitchType $switch