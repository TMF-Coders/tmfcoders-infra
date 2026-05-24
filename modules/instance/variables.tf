variable "instance_name" {
  description = "Name of the instance (lowercase, RFC1035-style)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.instance_name))
    error_message = "instance_name must be lowercase alphanumeric with hyphens."
  }
}

variable "instance_type" {
  description = "Scaleway commercial instance type (e.g. PLAY2-NANO, PRO2-S)"
  type        = string
  default     = "PRO2-S"
}

variable "image_label" {
  description = "Marketplace image label (e.g. ubuntu_jammy, ubuntu_noble)"
  type        = string
  default     = "ubuntu_noble"
}

variable "zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID applied to the instance"
  type        = string
}

variable "tags" {
  description = "Tags for the instance"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 10 && var.root_volume_size <= 1000
    error_message = "root_volume_size must be between 10 and 1000 GB."
  }
}

variable "root_volume_type" {
  description = "Root volume type (sbs_volume, b_ssd, l_ssd)"
  type        = string
  default     = "sbs_volume"

  validation {
    condition     = contains(["sbs_volume", "b_ssd", "l_ssd"], var.root_volume_type)
    error_message = "root_volume_type must be one of: sbs_volume, b_ssd, l_ssd."
  }
}

variable "additional_volume_ids" {
  description = "Additional block volume IDs to attach"
  type        = list(string)
  default     = []
}

variable "private_network_ids" {
  description = "List of private network IDs to attach the instance to"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Attach a routed public IP (discouraged in production - use a Load Balancer)"
  type        = bool
  default     = false
}

variable "cloud_init" {
  description = "cloud-init user data script"
  type        = string
  default     = ""
}

variable "admin_ssh_keys" {
  description = "Public SSH keys appended to root's authorized_keys at first boot"
  type        = list(string)
  default     = []
}
