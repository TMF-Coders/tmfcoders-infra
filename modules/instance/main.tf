/**
 * Instance Module - Scaleway
 * Hardened compute instance: private-network-only by default, encrypted
 * block storage, cloud-init bootstrap. A public IP is created only when
 * explicitly requested (production workloads sit behind a Load Balancer).
 */

data "scaleway_marketplace_image" "this" {
  label         = var.image_label
  instance_type = var.instance_type
  zone          = var.zone
}

resource "scaleway_instance_ip" "this" {
  count      = var.assign_public_ip ? 1 : 0
  type       = "routed_ipv4"
  project_id = var.project_id
  zone       = var.zone
}

resource "scaleway_instance_server" "this" {
  name              = var.instance_name
  type              = var.instance_type
  image             = data.scaleway_marketplace_image.this.id
  zone              = var.zone
  project_id        = var.project_id
  security_group_id = var.security_group_id
  tags              = var.tags

  # Public IP attached only on demand; private-network-only otherwise.
  ip_id = var.assign_public_ip ? scaleway_instance_ip.this[0].id : null

  root_volume {
    size_in_gb            = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  additional_volume_ids = var.additional_volume_ids

  dynamic "private_network" {
    for_each = var.private_network_ids
    content {
      pn_id = private_network.value
    }
  }

  user_data = {
    cloud-init = var.cloud_init
  }

  lifecycle {
    # cloud-init reruns and image label resolution must not force replacement.
    ignore_changes = [
      user_data,
      image,
    ]
  }
}
