/**
 * Network Module - Scaleway VPC v2
 * Creates a regional VPC, one or more private networks (each with its own
 * IPv4 subnet), and an optional Public Gateway providing NAT egress and an
 * SSH bastion. Equivalent to a GCP Shared VPC + Cloud NAT + IAP-style entry.
 */

resource "scaleway_vpc" "this" {
  name       = "${var.name_prefix}-vpc"
  project_id = var.project_id
  region     = var.region
  tags       = var.tags
}

resource "scaleway_vpc_private_network" "this" {
  for_each = var.private_networks

  name       = "${var.name_prefix}-${each.key}"
  vpc_id     = scaleway_vpc.this.id
  project_id = var.project_id
  region     = var.region
  tags       = concat(var.tags, ["pn:${each.key}"])

  ipv4_subnet {
    subnet = each.value.subnet
  }
}

#───────────────────────────────────────────────
# Public Gateway: NAT egress + SSH bastion
#───────────────────────────────────────────────
resource "scaleway_vpc_public_gateway_ip" "this" {
  count      = var.enable_public_gateway ? 1 : 0
  project_id = var.project_id
  zone       = var.zone
}

resource "scaleway_vpc_public_gateway" "this" {
  count = var.enable_public_gateway ? 1 : 0

  name            = "${var.name_prefix}-gateway"
  type            = var.public_gateway_type
  project_id      = var.project_id
  zone            = var.zone
  ip_id           = scaleway_vpc_public_gateway_ip.this[0].id
  bastion_enabled = var.bastion_enabled
  bastion_port    = var.bastion_port
  tags            = concat(var.tags, ["nat-gateway", "bastion"])
}

# Attach the gateway to every private network with NAT masquerade + default route
resource "scaleway_vpc_gateway_network" "this" {
  for_each = var.enable_public_gateway ? var.private_networks : {}

  gateway_id         = scaleway_vpc_public_gateway.this[0].id
  private_network_id = scaleway_vpc_private_network.this[each.key].id
  zone               = var.zone
  enable_masquerade  = true

  ipam_config {
    push_default_route = true
  }
}
