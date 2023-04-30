## gateway/vpn servers

locals {
  gateway_servers = {
    "site0" = {
      "public_ip"  = aws_eip.site0.public_ip
      "private_ip" = module.site0.gw_server.private_ip
    }
    "site1" = {
      "public_ip"  = aws_eip.site1.public_ip
      "private_ip" = module.site1.gw_server.private_ip
    }
  }
}

resource "wireguard_asymmetric_key" "vpn_keys" {
  for_each = local.sites
}

resource "local_file" "gateway_hostvars" {
  for_each = local.gateway_servers
  
  content = templatefile("templates/ansible/host_vars/wireguard.yml.tpl", {
    server_name = each.key
    site_domain = local.site_domains[each.key]
    studio_domain = var.studio_domain
    public_ip   = each.value.public_ip
    private_ip  = each.value.private_ip
    private_cidr_blocks = flatten([ local.sites[each.key].gateway_net, values(local.sites[each.key].internal_nets)])
    vpn_ip          = local.vpn_ips[each.key]
    vpn_netlen      = 24
    vpn_cidr_block  = var.vpn_settings.cidr_block
    vpn_listen_port = var.vpn_settings.listen_port
    vpn_private_key = wireguard_asymmetric_key.vpn_keys[each.key].private_key
    
    peers = [for peer in local.vpn_peers[each.key] :
      {
        name = peer
        public_ip = local.gateway_servers[peer].public_ip
        vpn_ip  = local.vpn_ips[peer]
        vpn_public_key = wireguard_asymmetric_key.vpn_keys[peer].public_key
        local_networks = flatten([local.sites[peer].gateway_net, values(local.sites[peer].internal_nets)])
      }
    ]
    
    dns_domain_servers = {
      for site, _ in local.sites : 
        local.site_domains[site] => [
          for k, v in local.samba_servers[site] : v.address
        ]
      if site != each.key
    }

    dns_upstream_servers = [ cidrhost(local.sites[each.key].gateway_net, 2) ]
  })

  filename        = "local/ansible/host_vars/${each.key}.yml"
  file_permission = "0640"
}

