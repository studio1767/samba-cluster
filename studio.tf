## create the public IPs

resource "aws_eip" "site0" {
  tags = {
    Name = var.site0.name
  }
  provider = aws.region0
}
resource "aws_eip" "site1" {
  tags = {
    Name = var.site1.name
  }
  provider = aws.region1
}

## create the sites

locals {
  site0_peers = merge(
    {
      remote_gateway = var.site1.gateway_net
    }, 
    var.site1.internal_nets,
    {
      "vpn" = var.vpn_settings.cidr_block
    }
  )

  site1_peers = merge(
    {
      remote_gateway = var.site0.gateway_net
    }, 
    var.site0.internal_nets,
    {
      "vpn" = var.vpn_settings.cidr_block
    }
  )
}


## site0 and extras

module "site0" {
  source = "./modules/site"
  providers = {
    aws = aws.region0
  }
  site_name = var.site0.name
  ssh_key_name = var.site0.name
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  public_ip_id = aws_eip.site0.id
  gateway_net = var.site0.gateway_net
  internal_nets = var.site0.internal_nets
  peer_subnets = local.site0_peers
  management_ip = local.management_ip

  gateway_access = {
    ssh = {
      source = local.management_net
      port = 22
    }
    vpn = {
      source = "${aws_eip.site1.public_ip}/32"
      port = var.vpn_settings.listen_port
    }
  }
}

resource "aws_vpc_dhcp_options" "site0" {
  provider = aws.region0

  domain_name = "${var.site0.name}.${var.studio_domain}"
  domain_name_servers = [ for server in local.samba0_servers : server.address ]
  tags = {
    Name = var.site0.name
  }
}

## site1 and extras

module "site1" {
  source = "./modules/site"
  providers = {
    aws = aws.region1
  }
  site_name = var.site1.name
  ssh_key_name = var.site1.name
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  public_ip_id = aws_eip.site1.id
  gateway_net = var.site1.gateway_net
  internal_nets = var.site1.internal_nets
  peer_subnets = local.site1_peers
  management_ip = local.management_ip

  gateway_access = {
    ssh = {
      source = local.management_net
      port = 22
    }
    vpn = {
      source = "${aws_eip.site0.public_ip}/32"
      port = 51820
    }
  }
}

resource "aws_vpc_dhcp_options" "site1" {
  provider = aws.region1

  domain_name = "${var.site1.name}.${var.studio_domain}"
  domain_name_servers = [ for server in local.samba1_servers : server.address ]
  tags = {
    Name = var.site1.name
  }
}

