#!/usr/bin/env bash

kerberos_realm=$1
netbios_domain=$2
admin_password=$3

/bin/rm -f /etc/samba/smb.conf

/usr/bin/samba-tool domain provision --use-rfc2307 \
   --realm=$${kerberos_realm} \
   --domain=$${netbios_domain} \
   --server-role=dc \
   --dns-backend=SAMBA_INTERNAL \
   --adminpass="$${admin_password}"

