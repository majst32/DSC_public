function set-DomainObjects {

param (
    [parameter(Mandatory=$True)]
    [string]$Domain,

    [parameter(Mandatory=$True)]
    [pscredential]$ADCreds,

    [parameter(Mandatory=$True)]
    [string]$NewName
    )

$DomainObj = Get-ADDomain $Domain
#Setup Computer Object in AD, add to Web Servers group before adding to domain
try
    {
        $CompObj = get-ADComputer -Identity $NewName
    }
catch {
    new-ADComputer -Name $NewName -sAMAccountName $NewName -DisplayName $NewName -DNSHostName "$NewName.($DomainObj.DNSRoot)" -Credential $ADCreds
    }

$WSGroup = get-ADGroup -Identity "Web Servers" -Credential $ADCreds 
Add-ADGroupMember -Identity $WSGroup -Members $CompObj.sAMAccountName -Credential $ADCreds
Restart-Computer -ComputerName $NewName
}

$Domain = "BLAH"
$ADCreds = Get-Credential -Message "Enter Domain Credentials" -UserName "$Domain\Administrator"
set-DomainObjects -Domain $Domain -ADCreds $ADCreds -NewName Pull