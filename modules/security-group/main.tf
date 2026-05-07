/**
 * Security Group Module for Scaleway
 * Equivalent to GCP IAM - Controls access to resources
 */

resource "scaleway_instance_security_group" "default" {
  name              = var.security_group_name
  description       = var.description
  inbound_default_policy  = var.inbound_default_policy
  outbound_default_policy = var.outbound_default_policy
  
  # SSH access (via private network or bastion)
  dynamic "inbound_rule" {
    for_each = var.allow_ssh ? [1] : []
    content {
      action = "accept"
      port   = 22
      ip     = var.ssh_source_ip
    }
  }
  
  # HTTP/HTTPS
  dynamic "inbound_rule" {
    for_each = var.allow_web ? [1] : []
    content {
      action = "accept"
      port   = "80,443"
      ip     = "0.0.0.0/0" # Restrict in production!
    }
  }
  
  # Custom rules
  dynamic "inbound_rule" {
    for_each = var.inbound_rules
    content {
      action = inbound_rule.value.action
      port   = lookup(inbound_rule.value, "port", null)
      ip     = lookup(inbound_rule.value, "ip", null)
    }
  }
  
  # Outbound: Allow all by default (we use NAT gateway)
  dynamic "outbound_rule" {
    for_each = var.outbound_rules
    content {
      action = outbound_rule.value.action
      port   = lookup(outbound_rule.value, "port", null)
      ip     = lookup(outbound_rule.value, "ip", null)
    }
  }
}
