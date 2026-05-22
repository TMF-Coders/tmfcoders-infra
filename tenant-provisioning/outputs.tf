output "tenant_project_ids" {
  description = "Map of tenant slug to created project ID - copy into each tenant's tfvars"
  value       = { for k, m in module.tenant : k => m.project_id }
}

output "client_access_keys" {
  description = "Map of tenant slug to client IAM access key (null when disabled)"
  value       = { for k, m in module.tenant : k => m.client_access_key }
}

output "client_secret_keys" {
  description = "Map of tenant slug to client IAM secret key"
  value       = { for k, m in module.tenant : k => m.client_secret_key }
  sensitive   = true
}
