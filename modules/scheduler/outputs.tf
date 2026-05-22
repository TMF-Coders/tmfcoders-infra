output "namespace_id" {
  description = "Serverless Function namespace ID"
  value       = scaleway_function_namespace.this.id
}

output "function_id" {
  description = "VM power scheduler function ID"
  value       = scaleway_function.power.id
}

output "power_off_cron" {
  description = "Active power-off cron schedule (UTC)"
  value       = var.power_off_cron
}

output "power_on_cron" {
  description = "Active power-on cron schedule (UTC)"
  value       = var.power_on_cron
}
