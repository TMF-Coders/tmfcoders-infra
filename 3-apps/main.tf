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
    endpoint                    = "s3.${var.region}.scw.cloud"
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
    endpoint                    = "s3.${var.region}.scw.cloud"
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

  volume_type       = "bssd"
  volume_size_in_gb = 50

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

#───────────────────────────────────────────────
# VM 1: OpenClaw (Matriz)
#───────────────────────────────────────────────
module "openclaw" {
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

  cloud_init = file("${path.module}/templates/openclaw-cloud-init.sh.tftpl")
}

#───────────────────────────────────────────────
# VM 2: Odoo 19 (Filial)
#───────────────────────────────────────────────
module "odoo" {
  source = "../modules/instance"

  instance_name     = "${local.name_prefix}-odoo-001"
  instance_type     = var.odoo_instance_type
  image_label       = "ubuntu_jammy"
  zone              = var.zone
  project_id        = var.project_id
  security_group_id = data.terraform_remote_state.org.outputs.security_group_apps_id
  tags              = concat(local.common_tags, ["odoo", "filial"])

  root_volume_size = 40
  root_volume_type = "sbs_volume"

  private_network_ids = [data.terraform_remote_state.network.outputs.apps_network_id]
  assign_public_ip    = false

  cloud_init = templatefile("${path.module}/templates/odoo-cloud-init.sh.tftpl", {
    db_host                   = scaleway_rdb_instance.odoo.load_balancer[0].ip
    db_port                   = scaleway_rdb_instance.odoo.load_balancer[0].port
    db_name                   = scaleway_rdb_database.odoo.name
    db_user                   = "odoo"
    db_password_secret_id     = scaleway_secret.odoo_db_password.id
    master_password_secret_id = data.terraform_remote_state.org.outputs.odoo_master_password_secret_id
    scw_access_key            = data.terraform_remote_state.org.outputs.odoo_workload_access_key
    scw_secret_key            = data.terraform_remote_state.org.outputs.odoo_workload_secret_key
    scw_project_id            = var.project_id
    scw_region                = var.region
  })
}

#───────────────────────────────────────────────
# Odoo private IP (IPAM) for the Load Balancer backend
#───────────────────────────────────────────────
data "scaleway_ipam_ip" "odoo" {
  count = var.enable_odoo_load_balancer ? 1 : 0

  resource {
    id   = module.odoo.instance_id
    type = "instance_server"
  }
  type = "ipv4"
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
  server_ips       = [data.scaleway_ipam_ip.odoo[0].address]

  health_check_http {
    uri  = "/web/health"
    code = 200
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

  name_prefix    = local.name_prefix
  project_id     = var.project_id
  region         = var.region
  zone           = var.zone
  server_ids     = [module.odoo.instance_id, module.openclaw.instance_id]
  scw_secret_key = data.terraform_remote_state.org.outputs.scheduler_workload_secret_key
  power_off_cron = var.power_off_cron
  power_on_cron  = var.power_on_cron
}
