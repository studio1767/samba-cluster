#!/usr/bin/env bash

site_domain=$1
admin_password=$2

/bin/rm -f /etc/samba/smb.conf

/usr/bin/samba-tool domain join $${site_domain} DC \
  --option='idmap_ldb:use rfc2307 = yes' \
  --username=administrator --password=$${admin_password}


