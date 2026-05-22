/**
 * Security Group Module - Scaleway
 * Stateful instance firewall. Default-deny inbound, explicit-allow rules.
 * Equivalent in spirit to a GCP firewall ruleset scoped to instances.
 */

resource "scaleway_instance_security_group" "this" {
  name                    = var.security_group_name
  description             = var.description
  project_id              = var.project_id
  inbound_default_policy  = var.inbound_default_policy
  outbound_default_policy = var.outbound_default_policy
  stateful                = true

  dynamic "inbound_rule" {
    for_each = var.inbound_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }

  dynamic "outbound_rule" {
    for_each = var.outbound_rules
    content {
      action     = outbound_rule.value.action
      protocol   = outbound_rule.value.protocol
      port       = outbound_rule.value.port
      port_range = outbound_rule.value.port_range
      ip_range   = outbound_rule.value.ip_range
    }
  }

  tags = var.tags
}
