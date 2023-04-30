## the ssh key

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_key_file" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "local/pki/${var.studio_code}"
  file_permission = "0600"
}

## ssh config file

resource "local_file" "ssh_config" {
  content = templatefile("templates/ssh.cfg.tpl", {
    ssh_key_file = local_file.ssh_key_file.filename
    gateway_servers = local.gateway_servers
    samba_servers   = local.samba_servers
  })
  filename        = "local/ssh.cfg"
  file_permission = "0640"
}

