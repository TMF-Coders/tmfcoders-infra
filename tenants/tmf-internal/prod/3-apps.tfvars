# Tenant: tmf-internal / Environment: prod / Layer: 3-apps
environment  = "prod"
tenant       = "tmf-internal"
cost_center  = "internal"
billing_mode = "project"
project_id   = "__PROJECT_ID__"
region       = "fr-par"
zone         = "fr-par-1"
state_bucket = "tmfcoders-terraform-state-a2b56"

# FinOps-optimised sizing for an internal, low-traffic Odoo.
# OpenClaw disabled for now.
enable_openclaw    = false
odoo_instance_type = "PLAY2-MICRO" # 2 vCPU / 8 GB burstable - DB offloaded to RDB

# Managed PostgreSQL: single-node, modest volume, shorter retention (internal).
rdb_node_type             = "DB-DEV-M"
rdb_is_ha                 = false
rdb_backup_retention_days = 14
rdb_volume_size_gb        = 20

enable_odoo_load_balancer = true
odoo_domain               = ""

# VM power schedule (cost saving) - UTC crons; defaults = 01:00-09:00 CET
enable_power_schedule = true
power_off_cron        = "0 0 * * *"
power_on_cron         = "0 8 * * *"
