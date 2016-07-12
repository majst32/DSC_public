function set-DomainObjects {

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')]

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
    Write-Verbose "Server $NewName not found."
    }

$WSGroup = get-ADGroup -Identity "Web Servers" -Credential $ADCreds -Properties *
try {
    Add-ADGroupMember -Identity $WSGroup -Members $CompObj.DistinguishedName -Credential $ADCreds
    Restart-Computer -ComputerName $NewName -Credential $ADCreds -Protocol WSMan -WsmanAuthentication Kerberos
    }

catch {
    write-verbose "Server not added to Web Servers Group."
    }
}

$Domain = "BLAH"
$ADCreds = Get-Credential -Message "Enter Domain Credentials" -UserName "$Domain\Administrator"
set-DomainObjects -Domain $Domain -ADCreds $ADCreds -NewName Pull -Verbose