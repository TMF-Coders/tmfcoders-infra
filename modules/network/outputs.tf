output "vpc_id" {
  description = "The VPC ID"
  value       = scaleway_vpc.this.id
}

output "private_network_ids" {
  description = "Map of private network short name to ID"
  value       = { for k, v in scaleway_vpc_private_network.this : k => v.id }
}

output "private_network_subnets" {
  description = "Map of private network short name to subnet CIDR"
  value       = { for k, v in var.private_networks : k => v.subnet }
}

output "public_gateway_id" {
  description = "The Public Gateway ID (null if disabled)"
  value       = var.enable_public_gateway ? scaleway_vpc_public_gateway.this[0].id : null
}

output "public_gateway_ip" {
  description = "The Public Gateway public IP (null if disabled)"
  value       = var.enable_public_gateway ? scaleway_vpc_public_gateway_ip.this[0].address : null
}

output "bastion_port" {
  description = "SSH bastion port on the Public Gateway"
  value       = var.enable_public_gateway && var.bastion_enabled ? var.bastion_port : null
}
