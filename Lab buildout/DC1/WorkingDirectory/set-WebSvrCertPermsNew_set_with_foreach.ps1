$Perms = "0e10c968-78fb-11d2-90d4-00c04f79dc55","a05b8cc2-17bc-4802-a710-e7c15ab866a2"

foreach ($Perm in $Perms) {
     
            #Set-Resource
                            Import-Module activedirectory
                            write-host $Perm
                            $WebServersGroup = get-adgroup -Identity "Web Servers" | Select-Object SID
                            $EnrollGUID = [GUID]::Parse($Perm)
                            $ACL = get-acl "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com"
                            $ACL.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $WebServersGroup.SID,'Allow',$EnrollGUID,'None'))
                            #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'ReadProperty','Allow'))
                            #$ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $WebServersGroup.SID,'GenericExecute','Allow'))
                            set-ACL "AD:CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" -AclObject $ACL
                            write-verbose "AutoEnroll permissions set for Web Servers Group"
                        }
 