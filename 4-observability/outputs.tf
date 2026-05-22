output "cockpit_logs_source_url" {
  description = "Cockpit logs source push URL"
  value       = scaleway_cockpit_source.logs.url
}

output "cockpit_metrics_source_url" {
  description = "Cockpit metrics source push URL"
  value       = scaleway_cockpit_source.metrics.url
}

output "cockpit_ingest_token" {
  description = "Cockpit ingestion token for log/metric agents"
  value       = scaleway_cockpit_token.ingest.secret_key
  sensitive   = true
}

output "grafana_user_login" {
  description = "Cockpit Grafana operations account login"
  value       = scaleway_cockpit_grafana_user.ops.login
}

output "grafana_user_password" {
  description = "Cockpit Grafana operations account password"
  value       = scaleway_cockpit_grafana_user.ops.password
  sensitive   = true
}

output "audit_logs_bucket" {
  description = "Object Storage bucket holding immutable audit logs"
  value       = scaleway_object_bucket.audit_logs.name
}

output "audit_logs_endpoint" {
  description = "Object Storage endpoint for the audit log bucket"
  value       = scaleway_object_bucket.audit_logs.endpoint
}
