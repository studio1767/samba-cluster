## Studio

variable "studio_name" {
  default = "Studio1767"
}

variable "studio_code" {
  default = "s1767"
}

variable "studio_domain" {
  default = "example.xyz"
}

locals {
  studio_domain_dn = join(",", formatlist("dc=%s", split(".", var.studio_domain)))
}


## Network

data "external" "my_public_ip" {
  program = ["scripts/my-public-ip.sh"]
}

locals {
  management_ip  = data.external.my_public_ip.result["my_public_ip"]
  management_net = "${local.management_ip}/32"
}


variable "site0" {
  type = object({
    name = string
    gateway_net = string
    internal_nets = map(string)
    samba_servers = map(string)
  })
  default = {
    name = "site0"
    gateway_net = "10.100.0.0/24"
    internal_nets = {
      net0 = "10.100.1.0/24"
      net1 = "10.100.2.0/24"
    }
    samba_servers = {
      net0 = "dc00"
      net1 = "dc01"
    }
  }
}

variable "site1" {
  type = object({
    name = string
    gateway_net = string
    internal_nets = map(string)
    samba_servers = map(string)
  })
  default = {
    name = "site1"
    gateway_net = "10.101.0.0/24"
    internal_nets = {
      net0 = "10.101.1.0/24"
      net1 = "10.101.2.0/24"
    }
    samba_servers = {
      net0 = "dc10"
      net1 = "dc11"
    }
  }
}

variable "samba_admin_password" {
  default = ""
  sensitive = true
}

locals {
  sites = {
    "site0" = var.site0
    "site1" = var.site1
  }

  site_domains = {
    "site0" = "${var.site0.name}.${var.studio_domain}"
    "site1" = "${var.site1.name}.${var.studio_domain}"
  }
}

variable "vpn_settings" {
  type = object({
    cidr_block = string
    listen_port = number
    })
  default = {
    cidr_block = "10.30.0.0/24"
    listen_port = 51820
  }
}

locals {
  vpn_ips = {
    "site0" = cidrhost(var.vpn_settings.cidr_block, 6),
    "site1" = cidrhost(var.vpn_settings.cidr_block, 7),
  }
  vpn_peers = {
    "site0" = ["site1"],
    "site1" = ["site0"]
  }
}

## AWS settings

variable "aws_profile0" {
  default = ""
}

variable "aws_region0" {
  default = ""
}

variable "aws_profile1" {
  default = ""
}

variable "aws_region1" {
  default = ""
}

variable "aws_instance_type" {
  default = "t3.micro"
}
