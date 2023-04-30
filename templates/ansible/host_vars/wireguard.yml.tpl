---
server_name: ${server_name}
studio_domain: ${studio_domain}
site_domain: ${site_domain}

public_ip: ${public_ip}
private_ip: ${private_ip}

private_cidr_blocks:
%{for _, net in private_cidr_blocks ~}
- ${net}
%{ endfor ~}

vpn_ip: ${vpn_ip}
vpn_netlen: ${vpn_netlen}
vpn_cidr_block: ${vpn_cidr_block}
vpn_listen_port: ${vpn_listen_port}
vpn_private_key: ${vpn_private_key}

peers:
%{ for peer in peers ~}
- name: ${peer.name}
  public_ip: ${peer.public_ip}
  vpn_ip: ${peer.vpn_ip}
  vpn_public_key: ${peer.vpn_public_key}
  local_networks:
%{for _, net in peer.local_networks ~}
  - ${net}
%{ endfor ~}
%{ endfor ~}


dns_domain_servers:
%{ for domain, servers in dns_domain_servers ~}
- domain: ${domain}
  servers:
%{ for server in servers ~}
  - ${server}
%{ endfor ~}
%{ endfor ~}

dns_upstream_servers:
%{ for server in dns_upstream_servers ~}
- ${server}
%{ endfor ~}
