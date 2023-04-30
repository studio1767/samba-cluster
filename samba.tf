
locals {
  samba0_servers = { for k, v in aws_instance.samba0 : k => {
    "name" = var.site0.samba_servers[k]
    "address" = v.private_ip
  }}
  samba1_servers = { for k, v in aws_instance.samba1 : k => {
    "name" = var.site1.samba_servers[k]
    "address" = v.private_ip
  }}
  samba_servers = {
    "site0" = local.samba0_servers
    "site1" = local.samba1_servers
  }
  
  samba_initial_servers = {
    "site0" = local.samba0_servers["net0"]
    "site1" = local.samba1_servers["net0"]
  }
  samba_join_servers = {
    "site0" = [ for k, v in local.samba0_servers : v if k != "net0" ]
    "site1" = [ for k, v in local.samba1_servers : v if k != "net0" ]
  }
}

data "aws_ami" "samba0" {
  provider = aws.region0

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

resource "aws_instance" "samba0" {
  for_each = var.site0.samba_servers
  
  provider = aws.region0
  
  instance_type = var.aws_instance_type
  ami           = data.aws_ami.samba0.id

  disable_api_termination     = false
  associate_public_ip_address = false
  source_dest_check           = true

  subnet_id                   = module.site0.internal_subnets[each.key].id
  key_name                    = module.site0.ssh_key_name
  vpc_security_group_ids      = [module.site0.internal_sg]

  tags = {
    Name = "${var.site0.name}-${each.value}"
  }
  
  user_data = <<-EOF
  #!/usr/bin/env bash
  hostnamectl set-hostname "${each.value}"
  EOF
}

data "aws_ami" "samba1" {
  provider = aws.region1

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

resource "aws_instance" "samba1" {
  for_each = var.site1.samba_servers
  
  provider = aws.region1
  
  instance_type = var.aws_instance_type
  ami           = data.aws_ami.samba1.id

  disable_api_termination     = false
  associate_public_ip_address = false
  source_dest_check           = true

  subnet_id                   = module.site1.internal_subnets[each.key].id
  key_name                    = module.site1.ssh_key_name
  vpc_security_group_ids      = [module.site1.internal_sg]

  tags = {
    Name = "${var.site1.name}-${each.value}"
  }
  
  user_data = <<-EOF
  #!/usr/bin/env bash
  hostnamectl set-hostname "${each.value}"
  EOF
}

resource "random_password" "site0" {
  length  = 24
  special = true
}

resource "random_password" "site1" {
  length  = 24
  special = true
}

locals {
  samba0_admin_password = var.samba_admin_password == "" ? random_password.site0.result : var.samba_admin_password
  samba1_admin_password = var.samba_admin_password == "" ? random_password.site1.result : var.samba_admin_password
}

resource "local_file" "samba0_hostvars" {
  for_each = local.samba0_servers
  
  content = templatefile("templates/ansible/host_vars/samba.yml.tpl", {
    server_name = each.value.name
    studio_domain = var.studio_domain
    site_domain = local.site_domains["site0"]
    private_ip  = each.value.address
    initial_samba = local.samba_initial_servers["site0"].address
    kerberos_realm = upper(local.site_domains["site0"])
    netbios_domain = upper(var.site0.name)
    admin_password = local.samba0_admin_password
    dns_forwarder  = cidrhost(var.site0.gateway_net, 6)
  })

  filename        = "local/ansible/host_vars/${each.value.name}.yml"
  file_permission = "0640"
}

resource "local_file" "samba1_hostvars" {
  for_each = local.samba1_servers
  
  content = templatefile("templates/ansible/host_vars/samba.yml.tpl", {
    server_name = each.value.name
    studio_domain = var.studio_domain
    site_domain = "${var.site1.name}.${var.studio_domain}"
    private_ip  = each.value.address
    initial_samba = local.samba_initial_servers["site1"].address
    kerberos_realm = upper(local.site_domains["site1"])
    netbios_domain = upper(var.site1.name)
    admin_password = local.samba1_admin_password
    dns_forwarder  = cidrhost(var.site1.gateway_net, 6)
  })

  filename        = "local/ansible/host_vars/${each.value.name}.yml"
  file_permission = "0640"
}
