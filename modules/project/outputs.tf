output "project_id" {
  description = "The Scaleway project ID"
  value       = scaleway_account_project.this.id
}

output "project_name" {
  description = "The Scaleway project name"
  value       = scaleway_account_project.this.name
}

output "organization_id" {
  description = "The Scaleway organization ID owning the project"
  value       = scaleway_account_project.this.organization_id
}

output "ssh_key_ids" {
  description = "Map of registered SSH key IDs"
  value       = { for k, v in scaleway_iam_ssh_key.this : k => v.id }
}
