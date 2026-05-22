output "security_group_main_id" {
  description = "Main tier security group ID"
  value       = module.security_group_main.security_group_id
}

output "security_group_apps_id" {
  description = "Apps tier security group ID"
  value       = module.security_group_apps.security_group_id
}

output "odoo_application_id" {
  description = "Odoo workload IAM application ID"
  value       = scaleway_iam_application.odoo.id
}

output "openclaw_application_id" {
  description = "OpenClaw workload IAM application ID"
  value       = scaleway_iam_application.openclaw.id
}

output "odoo_master_password_secret_id" {
  description = "Secret Manager ID for the Odoo master password"
  value       = scaleway_secret.odoo_master_password.id
}

output "odoo_workload_access_key" {
  description = "Odoo workload API access key"
  value       = scaleway_iam_api_key.odoo.access_key
}

output "odoo_workload_secret_key" {
  description = "Odoo workload API secret key (least-privilege: Secret Manager read only)"
  value       = scaleway_iam_api_key.odoo.secret_key
  sensitive   = true
}

output "openclaw_workload_access_key" {
  description = "OpenClaw workload API access key"
  value       = scaleway_iam_api_key.openclaw.access_key
}

output "openclaw_workload_secret_key" {
  description = "OpenClaw workload API secret key (least-privilege: Secret Manager read only)"
  value       = scaleway_iam_api_key.openclaw.secret_key
  sensitive   = true
}

output "scheduler_application_id" {
  description = "Scheduler workload IAM application ID"
  value       = scaleway_iam_application.scheduler.id
}

output "scheduler_workload_secret_key" {
  description = "Scheduler workload API secret key (Instances power off/on)"
  value       = scaleway_iam_api_key.scheduler.secret_key
  sensitive   = true
}
