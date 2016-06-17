[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')] 

param()

#Check if GPO exists, create if it does not.
try {
    $Null = get-gpo -name "PKI AutoEnroll" -ErrorAction Stop
    write-verbose "PKI AutoEnroll GPO already exists"
    }
catch
    {
    $Null = new-gpo -name "PKI AutoEnroll"
    Write-Verbose "Created new GPO PKI AutoEnroll"
    }

#check for first value set, set if it is not.
try {
    $RegValue1 = Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -ErrorAction Stop
    if ($RegValue1.Value -ne 7) {
        $Null = Set-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -Value 7 -Type DWord
        write-verbose "Set Autoenrollment value to 7."
        }
    else {
        Write-Verbose "AutoEnroll value already set to 7."
        }
    }
catch {
    $Null = Set-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -Value 7 -Type DWord
    Write-Verbose "Set AutoEnrollment value to 7."
    }
    
#Check for second value, set if it is not.    
try {
    $RegValue2 = Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -ErrorAction Stop
    if ($RegValue2.Value -ne 10) {
        $null = Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -value 10 -Type DWord
        write-verbose "Set Expiration Percent to 10."
        }
    else {
        Write-Verbose "Expiration Percent already set to 10."
        }
    }
catch {
    $Null = Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -value 10 -Type DWord
    write-verbose "Set Expiration Percent to 10."
    }

#Check for third value, set if it is not.
try {
    $RegValue3 = Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -ErrorAction Stop
    if ($RegValue2.Value -notmatch "MY") {
        $Null = Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -value "MY" -Type String
        write-verbose "Set Offline Expiration Store Name to MY."
        }
    else {
        write-verbose "Offline Expiration Store Name already set to MY."
        }
    }
catch {
    $Null = Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -value "MY" -Type String
    write-verbose "Set Offline Expiration Store Name to MY."
    }
$Null = New-GPLink -name "PKI AutoEnroll" -Target "dc=blah,dc=com" -LinkEnabled Yes -ErrorAction SilentlyContinue
write-verbose "GPO PKI AutoEnroll is linked."
write-verbose "Script set-autoenrollGPO complete."
#>