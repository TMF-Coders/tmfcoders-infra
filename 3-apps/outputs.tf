output "openclaw_instance_id" {
  description = "OpenClaw instance ID"
  value       = module.openclaw.instance_id
}

output "odoo_instance_id" {
  description = "Odoo instance ID"
  value       = module.odoo.instance_id
}

output "odoo_db_endpoint" {
  description = "Managed PostgreSQL endpoint for Odoo"
  value       = scaleway_rdb_instance.odoo.load_balancer[0].ip
}

output "odoo_db_name" {
  description = "Odoo database name"
  value       = scaleway_rdb_database.odoo.name
}

output "odoo_db_password_secret_id" {
  description = "Secret Manager ID holding the Odoo database password"
  value       = scaleway_secret.odoo_db_password.id
}

output "odoo_load_balancer_ip" {
  description = "Public IP of the Odoo Load Balancer"
  value       = var.enable_odoo_load_balancer ? scaleway_lb_ip.odoo[0].ip_address : null
}

output "odoo_url" {
  description = "Public URL for Odoo"
  value = var.enable_odoo_load_balancer ? (
    var.odoo_domain != "" ? "https://${var.odoo_domain}" : "http://${scaleway_lb_ip.odoo[0].ip_address}"
  ) : null
}
