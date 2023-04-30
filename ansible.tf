## the roles

locals {
  server_role = "server"
  gateway_role = "gateway"
  wireguard_role = "wireguard"
  dnsmasq_role = "dnsmasq"
  samba_initial_role = "samba-initial"
  samba_join_role = "samba-join"
}

## render the run script

resource "local_file" "run_playbook" {
  content = templatefile("templates/ansible/run-ansible.sh.tpl", {
      inventory_file = "inventory.ini"
    })
  filename = "local/ansible/run-ansible.sh"
  file_permission = "0755"
}


## render the playbook

resource "local_file" "playbook" {
  content = templatefile("templates/ansible/playbook.yml.tpl", {
      server_role        = local.server_role
      gateway_role       = local.gateway_role
      wireguard_role     = local.wireguard_role
      dnsmasq_role       = local.dnsmasq_role
      samba_initial_role = local.samba_initial_role
      samba_join_role    = local.samba_join_role
      
      site0_name                = var.site0.name
      site0_aws_profile         = var.aws_profile0
      site0_aws_region          = var.aws_region0
      site0_aws_vpc_id          = module.site0.vpc_id
      site0_aws_dhcp_options_id = aws_vpc_dhcp_options.site0.id
      site1_name                = var.site1.name
      site1_aws_profile         = var.aws_profile1
      site1_aws_region          = var.aws_region1
      site1_aws_vpc_id          = module.site1.vpc_id
      site1_aws_dhcp_options_id = aws_vpc_dhcp_options.site1.id

    })
  filename = "local/ansible/playbook.yml"
  file_permission = "0640"
}


## render the inventory file

resource "local_file" "inventory" {
  content = templatefile("templates/ansible/inventory.ini.tpl", {
    gateway_servers = local.gateway_servers
    samba_servers   = local.samba_servers
    samba_initial_servers = local.samba_initial_servers
    samba_join_servers  = local.samba_join_servers
  })
  filename = "local/ansible/inventory.ini"
  file_permission = "0640"
}


## the roles

resource "template_dir" "server" {
  source_dir      = "templates/ansible-roles/${local.server_role}"
  destination_dir = "local/ansible/roles/${local.server_role}"

  vars = {}
}

resource "template_dir" "gateway" {
  source_dir      = "templates/ansible-roles/${local.gateway_role}"
  destination_dir = "local/ansible/roles/${local.gateway_role}"

  vars = {}
}

resource "template_dir" "wireguard" {
  source_dir      = "templates/ansible-roles/${local.wireguard_role}"
  destination_dir = "local/ansible/roles/${local.wireguard_role}"

  vars = {}
}

resource "template_dir" "dnsmasq" {
  source_dir      = "templates/ansible-roles/${local.dnsmasq_role}"
  destination_dir = "local/ansible/roles/${local.dnsmasq_role}"

  vars = {}
}

resource "template_dir" "samba_initial" {
  source_dir      = "templates/ansible-roles/${local.samba_initial_role}"
  destination_dir = "local/ansible/roles/${local.samba_initial_role}"

  vars = {}
}

resource "template_dir" "samba_join" {
  source_dir      = "templates/ansible-roles/${local.samba_join_role}"
  destination_dir = "local/ansible/roles/${local.samba_join_role}"

  vars = {}
}
