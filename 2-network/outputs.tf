output "vpc_id" {
  description = "The VPC ID"
  value       = module.network.vpc_id
}

output "tmf_network_id" {
  description = "TMF (Matriz) private network ID"
  value       = module.network.private_network_ids["tmf"]
}

output "apps_network_id" {
  description = "Apps (Filial) private network ID"
  value       = module.network.private_network_ids["apps"]
}

output "tmf_subnet" {
  description = "TMF subnet CIDR"
  value       = module.network.private_network_subnets["tmf"]
}

output "apps_subnet" {
  description = "Apps subnet CIDR"
  value       = module.network.private_network_subnets["apps"]
}

output "public_gateway_id" {
  description = "Public Gateway ID"
  value       = module.network.public_gateway_id
}

output "public_gateway_ip" {
  description = "Public Gateway public IP (bastion endpoint)"
  value       = module.network.public_gateway_ip
}

output "bastion_port" {
  description = "SSH bastion port on the Public Gateway"
  value       = module.network.bastion_port
}
