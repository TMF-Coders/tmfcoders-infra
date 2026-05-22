output "security_group_id" {
  description = "The security group ID"
  value       = scaleway_instance_security_group.this.id
}

output "security_group_name" {
  description = "The security group name"
  value       = scaleway_instance_security_group.this.name
}
