/**
 * Organization Layer - Scaleway
 * Security perimeter: instance security groups for the main and apps tiers.
 * Default-deny inbound; traffic is allowed only between private subnets.
 * See: iam.tf (workload identities), secrets.tf (Secret Manager).
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

  # Private address plan (shared across layers).
  vpc_supernet = "10.10.0.0/16"
  tmf_subnet   = "10.10.10.0/24"
  apps_subnet  = "10.10.20.0/24"
}

#───────────────────────────────────────────────
# Security group: main tier (bastion-reachable hosts)
#───────────────────────────────────────────────
module "security_group_main" {
  source = "../modules/security-group"

  security_group_name = "${local.name_prefix}-main"
  description         = "Main tier - restrictive, private SSH only"
  project_id          = var.project_id
  tags                = concat(local.common_tags, ["tier:main"])

  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rules = [
    {
      action   = "accept"
      protocol = "TCP"
      port     = 22
      ip_range = local.vpc_supernet
    },
  ]
}

#───────────────────────────────────────────────
# Security group: apps tier (Odoo + OpenClaw)
#───────────────────────────────────────────────
module "security_group_apps" {
  source = "../modules/security-group"

  security_group_name = "${local.name_prefix}-apps"
  description         = "Apps tier - Odoo + OpenClaw, internal traffic only"
  project_id          = var.project_id
  tags                = concat(local.common_tags, ["tier:apps"])

  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rules = [
    {
      action   = "accept"
      protocol = "TCP"
      port     = 22
      ip_range = local.vpc_supernet
    },
    {
      action   = "accept"
      protocol = "TCP"
      port     = 8069 # Odoo HTTP
      ip_range = local.apps_subnet
    },
    {
      action   = "accept"
      protocol = "TCP"
      port     = 8072 # Odoo longpolling / websocket
      ip_range = local.apps_subnet
    },
  ]
}
