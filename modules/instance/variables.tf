variable "instance_name" {
  description = "Name of the instance"
  type        = string;
}

variable "instance_type" {
  description = "Instance type (e.g., DEV1-S, GP1-M)"
  type        = string;
  default     = "DEV1-S"
}

variable "image_id" {
  description = "Image ID (Ubuntu, Debian, etc.)"
  type        = string;
  default     = "ubuntu_jammy" # Ubuntu 22.04 LTS
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string;
}

variable "tags" {
  description = "Tags for the instance"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number;
  default     = 20;
}

variable "root_volume_type" {
  description = "Root volume type (l, sc, bssd)"
  type        = string;
  default     = "bssd" # Balanced SSD 
}

variable "addtional_volume_ids" {
  description = "Additional volume IDs to attach"
  type        = list(string)
  default     = []
}

variable "private_networks" {
  description = "Private networks to attach"
  type = list(object({
    pn_id  = string;
    pnic_id = string;
  }))
  default = []
}

variable "assign_public_ip" {
  description = "Assign public IP (NOT RECOMMENDED for PROD)"
  type        = bool;
  default     = false;
}

variable "user_data" {
  description = "User data / startup script"
  type        = string;
  default     = null;
}
