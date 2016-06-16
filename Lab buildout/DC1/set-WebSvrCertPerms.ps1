#Grant Domain Computers permission to enroll for Web Server Certificate Template
#Must be run with EA permissions

dsacls "CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=blah,DC=com" /G "BLAH\Domain Computers:CA;Enroll"