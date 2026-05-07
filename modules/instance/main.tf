/**
 * Instance Module for Scaleway
 * Equivalent to GCP compute_instance
 * European cloud provider - GDPR compliant
 */

resource "scaleway_instance_server" "instance" {
  name              = var.instance_name
  type              = var.instance_type
  image             = var.image_id
  security_group_id = var.security_group_id
  tags              = var.tags
  
  root_volume {
    size_in_gb = var.root_volume_size
    volume_type = var.root_volume_type
  }
  
  # Additional volumes
  dynamic "additional_volume_ids" {
    for_each = var.additional_volume_ids
    content {
      volume_id = additional_volume_ids.value
    }
  }
  
  # Private network (equivalent to VPC)
  dynamic "private_network" {
    for_each = var.private_networks
    content {
      pn_id = private_network.value.pn_id
      pnic_id = private_network.value.pnic_id
    }
  }
  
  # Public IP (disable for production!)
  enable_dynamic_ip = var.assign_public_ip
  
  # User data (startup script)
  user_data = var.user_data
}

# Public IP (if enabled - NOT RECOMMENDED FOR PROD)
resource "scaleway_instance_ip" "public" {
  count       = var.assign_public_ip ? 1 : 0
  server_id   = scaleway_instance_server.instance.id
  type        = "public"
  reverse    = "${var.instance_name}.tmfcoders.com"
}
