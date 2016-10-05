import-module activedirectory

#Test-TargetResource
$WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
if ($WebServerCertACL -eq $Null) {
    write-verbose "Web Servers Group does not have permissions on Web Server template"
    Return $False
    }
elseif (($WebServerCertACL -like "*ExtendedRight*") -and ($WebServerCertACL.ObjectType -notcontains "a05b8cc2-17bc-4802-a710-e7c15ab866a2")) {
    write-verbose "Web Servers group has permission, but not AutoEnroll"
    Return $False
    }
else {
    write-verbose "ACL on Web Server Template is set to AutoEnroll for Web Servers Group"
    Return $True
    }

#Set-TargetResource
$WebServersGroup = get-adgroup -Identity "Web Servers" | Select-Object SID
$EnrollGUID = [GUID]::Parse('a05b8cc2-17bc-4802-a710-e7c15ab866a2')
$ACL = get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
$ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
set-ACL "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
write-verbose "AutoEnroll permissions set for Web Servers Group"

#Get-TargetResource
$WebServerCertACL = (get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com").Access | Where-Object {$_.IdentityReference -like "*Web Servers"}
if ($WebServerCertACL -ne $Null) {
    return $WebServerCertACL
    }
else {
    Return @{}
    }