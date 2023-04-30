## the ssh key pair

resource "aws_key_pair" "ssh_key" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}


## site vpc

resource "aws_vpc" "site" {
  cidr_block = var.gateway_net
  enable_dns_support = true
  enable_dns_hostnames = false
  tags = {
    Name = var.site_name
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "internal_nets" {
  for_each   = var.internal_nets
  vpc_id     = aws_vpc.site.id
  cidr_block = each.value
}

## tag default route table and security group
##   ... and neuter the default security group

resource "aws_default_route_table" "site" {
  default_route_table_id = aws_vpc.site.default_route_table_id
  tags = {
    Name = "${var.site_name}-default"
  }
}

resource "aws_default_security_group" "site" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = "${var.site_name}-default"
  }
}

## the internet gateway

resource "aws_internet_gateway" "site" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = var.site_name
  }
}

## the gateway network

resource "aws_subnet" "gateway" {
  vpc_id     = aws_vpc.site.id
  cidr_block = var.gateway_net
  availability_zone = local.gateway_zone

  tags = {
    Name = "${var.site_name}-gw"
  }
}

data "aws_ami" "gateway" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "gateway" {
  instance_type = var.aws_instance_type
  ami           = data.aws_ami.gateway.id

  disable_api_termination     = false
  associate_public_ip_address = false
  source_dest_check           = false

  subnet_id                   = aws_subnet.gateway.id
  private_ip                  = cidrhost(aws_subnet.gateway.cidr_block, 6)
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [aws_security_group.gateway.id]

  tags = {
    Name = "${var.site_name}-gw"
  }
  
  user_data = <<-EOF
  #!/usr/bin/env bash
  hostnamectl set-hostname ${var.site_name}-gw
  EOF

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

resource "aws_eip_association" "gateway" {
  instance_id   = aws_instance.gateway.id
  allocation_id = var.public_ip_id
}

resource "aws_route_table_association" "gateway" {
  route_table_id = aws_route_table.gateway.id
  subnet_id      = aws_subnet.gateway.id
}

resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = "${var.site_name}-gw"
  }
}

resource "aws_route" "gateway_default" {
  route_table_id         = aws_route_table.gateway.id
  gateway_id             = aws_internet_gateway.site.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "gateway" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = "${var.site_name}-gw"
  }
}

resource "aws_security_group_rule" "gateway_all_out" {
  security_group_id = aws_security_group.gateway.id
  type        = "egress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "gateway_self" {
  security_group_id = aws_security_group.gateway.id
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  self        = true
}

resource "aws_security_group_rule" "gateway_external" {
  for_each = var.gateway_access
  
  security_group_id = aws_security_group.gateway.id
  type        = "ingress"
  protocol    = "tcp"
  from_port   = each.value.port
  to_port     = each.value.port
  cidr_blocks = [ each.value.source ]
}

resource "aws_security_group_rule" "gateway_internal" {
  security_group_id = aws_security_group.gateway.id
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = [ for _, v in var.internal_nets : v ]
}


## the internal networks

resource "aws_subnet" "internal" {
  for_each   = var.internal_nets
  vpc_id     = aws_vpc.site.id
  cidr_block = each.value
  availability_zone = local.internal_zones[each.key]

  tags = {
    Name = "${var.site_name}-${each.key}"
  }
  
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.internal_nets,
  ]
}

resource "aws_route_table_association" "internal" {
  for_each       = aws_subnet.internal

  route_table_id = aws_route_table.internal.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = "${var.site_name}-internal"
  }
}

resource "aws_route" "internal_default" {
  route_table_id         = aws_route_table.internal.id
  network_interface_id   = aws_instance.gateway.primary_network_interface_id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "internal" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = "${var.site_name}-internal"
  }
}

resource "aws_security_group_rule" "internal_all_out" {
  security_group_id = aws_security_group.internal.id
  type        = "egress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "internal_self" {
  security_group_id = aws_security_group.internal.id
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  self        = true
}

resource "aws_security_group_rule" "internal_gateway" {
  security_group_id = aws_security_group.internal.id
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = [ var.gateway_net ]
}

resource "aws_security_group_rule" "internal_peers" {
  security_group_id = aws_security_group.internal.id
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = values(var.peer_subnets)
}
