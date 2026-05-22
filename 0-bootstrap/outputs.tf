output "project_id" {
  description = "The platform (landing-zone) project ID - holds shared foundation resources"
  value       = module.project.project_id
}

output "organization_id" {
  description = "The Scaleway organization ID"
  value       = module.project.organization_id
}

output "state_bucket_name" {
  description = "Name of the Terraform state bucket - use it in every backend.hcl"
  value       = scaleway_object_bucket.state.name
}

output "state_bucket_endpoint" {
  description = "S3-compatible endpoint for the state bucket"
  value       = "s3.${var.region}.scw.cloud"
}

output "terraform_ci_application_id" {
  description = "IAM application ID used by the CI pipeline"
  value       = scaleway_iam_application.terraform_ci.id
}

output "terraform_ci_access_key" {
  description = "CI API access key - store as SCW_ACCESS_KEY GitHub secret"
  value       = scaleway_iam_api_key.terraform_ci.access_key
  sensitive   = true
}

output "terraform_ci_secret_key" {
  description = "CI API secret key - store as SCW_SECRET_KEY GitHub secret"
  value       = scaleway_iam_api_key.terraform_ci.secret_key
  sensitive   = true
}
