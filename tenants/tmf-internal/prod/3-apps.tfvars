# Tenant: tmf-internal / Environment: prod / Layer: 3-apps
environment  = "prod"
tenant       = "tmf-internal"
cost_center  = "internal"
billing_mode = "project"
project_id   = "91ecaf9a-8b9b-40bd-87cf-0d93a2d7cfe6"
region       = "fr-par"
zone         = "fr-par-1"
state_bucket = "tmfcoders-terraform-state-a2b56"

# FinOps-optimised sizing for an internal, low-traffic Odoo.
# OpenClaw disabled for now.
enable_openclaw    = false
odoo_instance_type = "PRO2-XXS" # 2 vCPU / 8 GB - DB offloaded to RDB; FinOps-optimal

# Managed PostgreSQL: single-node, modest volume, shorter retention (internal).
rdb_node_type             = "DB-DEV-M"
rdb_is_ha                 = false
rdb_backup_retention_days = 14
rdb_volume_size_gb        = 20

enable_odoo_load_balancer = true
odoo_domain               = "admin.tmfcoders.com"

# VM power schedule (cost saving) - UTC crons; defaults = 01:00-09:00 CET
enable_power_schedule = true
power_off_cron        = "0 0 * * *"
power_on_cron         = "0 8 * * *"

# Admin SSH keys injected into root's authorized_keys at first boot.
admin_ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhTqQwucVnRn6gO11xM6fR6PqH2hmubcRiHSPR7b4qz rmorgade@MacBook-Pro-de-Ruben.local",
]

# Private-network only; public ingress goes through the Load Balancer.
odoo_assign_public_ip = false
admin_root_password   = ""
