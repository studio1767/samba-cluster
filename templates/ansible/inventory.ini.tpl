[gateways]
%{ for name, _ in gateway_servers ~}
${name}
%{ endfor ~}

[samba]
%{ for _, servers in samba_servers ~}
%{ for _, server in servers ~}
${server.name}
%{ endfor ~}
%{ endfor ~}

[samba_initial]
%{ for _, server in samba_initial_servers ~}
${server.name}
%{ endfor ~}

[samba_join]
%{ for _, servers in samba_join_servers ~}
%{ for server in servers ~}
${server.name}
%{ endfor ~}
%{ endfor ~}
