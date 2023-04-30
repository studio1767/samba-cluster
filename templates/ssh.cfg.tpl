
# gateways
%{ for key, value in gateway_servers ~}
Host ${key}
  Hostname ${value.public_ip}
%{ endfor ~}

# internal servers
%{ for gateway, servers in samba_servers ~}
%{ for key, server in servers ~}
Host ${server.name}
  Hostname ${server.address}
  ProxyJump ${gateway}
%{ endfor ~}
%{ endfor ~}


Host *
  User ubuntu
  IdentityFile ${ssh_key_file}
  IdentitiesOnly yes

