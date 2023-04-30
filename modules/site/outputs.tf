
output "name" {
  value = var.site_name
}

output "vpc_id" {
  value = aws_vpc.site.id
}

output "gateway_net" {
  value = var.gateway_net
}

output "internal_nets" {
  value = var.internal_nets
}

output "internal_net_ids" {
  value = { for name, subnet in aws_subnet.internal: name => subnet.id }
}

data "aws_eip" "gw_public_ip" {
  id = var.public_ip_id
}

output "gw_server" {
  value = aws_instance.gateway
}

output "gw_public_ip" {
  value = data.aws_eip.gw_public_ip.public_ip
}

output "gw_private_ip" {
  value = aws_instance.gateway.private_ip
}

output "internal_subnets" {
  value = aws_subnet.internal
}

output "internal_sg" {
  value = aws_security_group.internal.id
}

output "ssh_key_name" {
  value = var.ssh_key_name
}