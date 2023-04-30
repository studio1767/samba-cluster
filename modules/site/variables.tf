
variable "site_name" {
  default = ""
}

variable "public_ip_id" {
  default = ""
}

variable "gateway_net" {
  default = "10.151.0.0/24"
}

variable "gateway_access" {
  type = map(object({
    source = string
    port = number
  }))
  default = {
    ssh = {
      source = "192.168.1.1/32"
      port = 22
    }
  }
}

variable "internal_nets" {
  type = map(string)
  default = {
    net0 = "10.151.1.0/24"
    net1 = "10.151.2.0/24"
  }
}

variable "peer_subnets" {
  type = map(string)
  default = {
    net = "10.163.0.0/24"
  }
}

variable "ssh_key_name" {
  default = ""
}

variable "ssh_public_key" {
  default = ""
}

variable "management_ip" {
  default = ""
}

variable "aws_instance_type" {
  default = "t3.micro"
}

data "aws_availability_zones" "site" {
  state = "available"
}

locals {
  num_zones = length(data.aws_availability_zones.site.names)
  gateway_zone = element(data.aws_availability_zones.site.names, local.num_zones - 1)
  internal_zones = {
    net0 = element(data.aws_availability_zones.site.names, local.num_zones - 2)
    net1 = element(data.aws_availability_zones.site.names, local.num_zones - 3)
  }
}

