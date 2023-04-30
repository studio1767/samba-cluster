#!/usr/bin/env bash

/bin/rm /etc/samba/smb.conf

/usr/bin/samba-tool domain join ${samba_domain} DC \
   --username=administrator --password=${admin_password}


