output "instance_id" {
  description = "The instance ID"
  value       = scaleway_instance_server.this.id
}

output "instance_name" {
  description = "The instance name"
  value       = scaleway_instance_server.this.name
}

output "private_ips" {
  description = "List of private IPs assigned to the instance via IPAM"
  value       = scaleway_instance_server.this.private_ips
}

output "private_ip" {
  description = "First IPv4 private address of the instance (null if none)"
  value       = try([for ip in scaleway_instance_server.this.private_ips : ip.address if length(regexall(":", ip.address)) == 0][0], null)
}

output "public_ip" {
  description = "The instance public IP (null when private-network-only)"
  value       = var.assign_public_ip ? scaleway_instance_ip.this[0].address : null
}
