function get-xdgmime{Get-Content /usr/share/applications/mimeinfo.cache|% {($_.split('=',2))[0]} }
