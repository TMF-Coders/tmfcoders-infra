/**
 * Network Layer - Scaleway VPC v2
 * One regional VPC with two private networks (tmf, apps) and a Public
 * Gateway providing NAT egress plus an SSH bastion. No workload is ever
 * exposed directly to the internet.
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

module "network" {
  source = "../modules/network"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region
  zone        = var.zone
  tags        = local.common_tags

  private_networks = {
    tmf  = { subnet = "10.10.10.0/24" } # Matriz - OpenClaw
    apps = { subnet = "10.10.20.0/24" } # Filial - Odoo
  }

  enable_public_gateway = true
  public_gateway_type   = var.public_gateway_type
  bastion_enabled       = true
  bastion_port          = 61000
}
