output "project_id" {
  description = "The tenant's Scaleway project ID"
  value       = scaleway_account_project.this.id
}

output "project_name" {
  description = "The tenant's Scaleway project name"
  value       = scaleway_account_project.this.name
}

output "client_access_key" {
  description = "Client IAM access key (null when client access is disabled)"
  value       = var.create_client_access ? scaleway_iam_api_key.client[0].access_key : null
}

output "client_secret_key" {
  description = "Client IAM secret key (null when client access is disabled)"
  value       = var.create_client_access ? scaleway_iam_api_key.client[0].secret_key : null
  sensitive   = true
}
