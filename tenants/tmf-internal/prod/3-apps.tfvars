# Tenant: tmf-internal / Environment: prod / Layer: 3-apps
environment  = "prod"
tenant       = "tmf-internal"
cost_center  = "internal"
billing_mode = "project"
project_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
region       = "fr-par"
zone         = "fr-par-1"
state_bucket = "tmfcoders-terraform-state-CHANGEME"

openclaw_instance_type    = "PRO2-S"
odoo_instance_type        = "PRO2-M"
rdb_node_type             = "DB-GP-S"
rdb_is_ha                 = true
rdb_backup_retention_days = 30

enable_odoo_load_balancer = true
odoo_domain               = ""

# VM power schedule (cost saving) - UTC crons; defaults = 01:00-09:00 CET
enable_power_schedule = true
power_off_cron        = "0 0 * * *"
power_on_cron         = "0 8 * * *"
