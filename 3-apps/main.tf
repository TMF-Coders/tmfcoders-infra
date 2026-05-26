/**
 * Apps Layer - Scaleway
 * Deploys OpenClaw (Matriz) and Odoo 19 (Filial). Odoo runs against a
 * Managed PostgreSQL cluster and is fronted by an HTTPS Load Balancer.
 * Every VM is private-network-only; secrets are pulled from Secret Manager.
 */

locals {
  name_prefix = "${var.tenant}-${var.environment}"

  common_tags = [
    "environment:${var.environment}",
    "tenant:${var.tenant}",
    "cost-center:${var.cost_center}",
    "billing-mode:${var.billing_mode}",
    "billable:true",
    "managed_by:terraform",
    "organization:tmfcoders",
  ]
}

#───────────────────────────────────────────────
# Cross-layer state
#───────────────────────────────────────────────
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket                      = var.state_bucket
    key                         = "tenants/${var.tenant}/1-org/${var.environment}/terraform.tfstate"
    region                      = var.region
    endpoints                   = { s3 = "https://s3.${var.region}.scw.cloud" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket                      = var.state_bucket
    key                         = "tenants/${var.tenant}/2-network/${var.environment}/terraform.tfstate"
    region                      = var.region
    endpoints                   = { s3 = "https://s3.${var.region}.scw.cloud" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

#───────────────────────────────────────────────
# Managed PostgreSQL for Odoo
#───────────────────────────────────────────────
resource "random_password" "odoo_db" {
  length           = 32
  special          = true
  override_special = "!@#%*-_=+"
}

resource "scaleway_secret" "odoo_db_password" {
  name        = "${var.tenant}-${var.environment}-odoo-db-password"
  description = "Odoo Managed PostgreSQL password"
  project_id  = var.project_id
  path        = "/tenants/${var.tenant}/${var.environment}"
  tags        = ["odoo", "database-password", var.environment]
}

resource "scaleway_secret_version" "odoo_db_password" {
  secret_id = scaleway_secret.odoo_db_password.id
  data      = random_password.odoo_db.result
}

resource "scaleway_rdb_instance" "odoo" {
  name          = "${local.name_prefix}-odoo-pg"
  project_id    = var.project_id
  region        = var.region
  node_type     = var.rdb_node_type
  engine        = "PostgreSQL-16"
  is_ha_cluster = var.rdb_is_ha

  user_name = "odoo"
  password  = random_password.odoo_db.result

  volume_type       = "sbs_5k"
  volume_size_in_gb = var.rdb_volume_size_gb

  disable_backup            = false
  backup_schedule_frequency = 24
  backup_schedule_retention = var.rdb_backup_retention_days
  backup_same_region        = true

  private_network {
    pn_id       = data.terraform_remote_state.network.outputs.apps_network_id
    enable_ipam = true
  }

  tags = local.common_tags
}

resource "scaleway_rdb_database" "odoo" {
  instance_id = scaleway_rdb_instance.odoo.id
  name        = "odoo"
}

# Grant the Odoo RDB user full privileges on its database.
# Scaleway RDB does NOT auto-grant the instance user on databases created
# via the API; without this the connection fails with "permission denied".
resource "scaleway_rdb_privilege" "odoo" {
  instance_id   = scaleway_rdb_instance.odoo.id
  user_name     = "odoo"
  database_name = scaleway_rdb_database.odoo.name
  permission    = "all"
}

#───────────────────────────────────────────────
# VM 1: OpenClaw (Matriz)
#───────────────────────────────────────────────
module "openclaw" {
  count  = var.enable_openclaw ? 1 : 0
  source = "../modules/instance"

  instance_name     = "${local.name_prefix}-openclaw-001"
  instance_type     = var.openclaw_instance_type
  image_label       = "ubuntu_jammy"
  zone              = var.zone
  project_id        = var.project_id
  security_group_id = data.terraform_remote_state.org.outputs.security_group_main_id
  tags              = concat(local.common_tags, ["openclaw", "matriz"])

  private_network_ids = [data.terraform_remote_state.network.outputs.tmf_network_id]
  assign_public_ip    = false
  admin_ssh_keys      = var.admin_ssh_keys

  cloud_init = file("${path.module}/templates/openclaw-cloud-init.sh.tftpl")
}

#───────────────────────────────────────────────
# VM 2: Odoo 19 (Filial)
#───────────────────────────────────────────────
module "odoo" {
  source = "../modules/instance"

  instance_name     = "${local.name_prefix}-odoo-001"
  instance_type     = var.odoo_instance_type
  image_label       = "ubuntu_noble" # 24.04 = Python 3.12 (Odoo 19 requires 3.11+)
  zone              = var.zone
  project_id        = var.project_id
  security_group_id = data.terraform_remote_state.org.outputs.security_group_apps_id
  tags              = concat(local.common_tags, ["odoo", "filial"])

  root_volume_size = 40
  root_volume_type = "sbs_volume"

  private_network_ids = [data.terraform_remote_state.network.outputs.apps_network_id]
  assign_public_ip    = var.odoo_assign_public_ip
  admin_ssh_keys      = var.admin_ssh_keys
  admin_root_password = var.admin_root_password

  cloud_init = templatefile("${path.module}/templates/odoo-cloud-init.sh.tftpl", {
    db_host         = scaleway_rdb_instance.odoo.private_network[0].ip
    db_port         = scaleway_rdb_instance.odoo.private_network[0].port
    db_name         = scaleway_rdb_database.odoo.name
    db_user         = "odoo"
    db_password     = random_password.odoo_db.result
    master_password = data.terraform_remote_state.org.outputs.odoo_master_password
  })
}

#───────────────────────────────────────────────
# Public HTTPS Load Balancer for Odoo
#───────────────────────────────────────────────
resource "scaleway_lb_ip" "odoo" {
  count      = var.enable_odoo_load_balancer ? 1 : 0
  project_id = var.project_id
  zone       = var.zone
}

resource "scaleway_lb" "odoo" {
  count = var.enable_odoo_load_balancer ? 1 : 0

  name       = "${local.name_prefix}-odoo-lb"
  project_id = var.project_id
  zone       = var.zone
  type       = "LB-S"
  ip_ids     = [scaleway_lb_ip.odoo[0].id]
  tags       = local.common_tags

  private_network {
    private_network_id = data.terraform_remote_state.network.outputs.apps_network_id
  }
}

resource "scaleway_lb_backend" "odoo" {
  count = var.enable_odoo_load_balancer ? 1 : 0

  lb_id            = scaleway_lb.odoo[0].id
  name             = "odoo-http"
  forward_protocol = "http"
  forward_port     = 8069
  server_ips       = [module.odoo.private_ip]

  health_check_http {
    uri         = "/web/health"
    code        = 200
    host_header = "odoo.internal"
  }
}

resource "scaleway_lb_certificate" "odoo" {
  count = var.enable_odoo_load_balancer && var.odoo_domain != "" ? 1 : 0

  lb_id = scaleway_lb.odoo[0].id
  name  = "${local.name_prefix}-odoo-cert"

  letsencrypt {
    common_name = var.odoo_domain
  }
}

resource "scaleway_lb_frontend" "odoo" {
  count = var.enable_odoo_load_balancer ? 1 : 0

  lb_id        = scaleway_lb.odoo[0].id
  backend_id   = scaleway_lb_backend.odoo[0].id
  name         = "odoo-https"
  inbound_port = var.odoo_domain != "" ? 443 : 80

  certificate_ids = var.odoo_domain != "" ? [scaleway_lb_certificate.odoo[0].id] : []
}

#───────────────────────────────────────────────
# VM power scheduler (cost saving: VMs off 01:00-09:00 CET)
#───────────────────────────────────────────────
module "scheduler" {
  count  = var.enable_power_schedule ? 1 : 0
  source = "../modules/scheduler"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region
  zone        = var.zone
  server_ids = concat(
    [module.odoo.instance_id],
    var.enable_openclaw ? [module.openclaw[0].instance_id] : [],
  )
  scw_secret_key = data.terraform_remote_state.org.outputs.scheduler_workload_secret_key
  power_off_cron = var.power_off_cron
  power_on_cron  = var.power_on_cron
}
