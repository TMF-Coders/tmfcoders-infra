variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = ""
}

variable "inbound_default_policy" {
  description = "Default policy for inbound traffic"
  type        = string
  default     = "drop"
}

variable "outbound_default_policy" {
  description = "Default policy for outbound traffic"
  type        = string
  default     = "accept"
}

variable "allow_ssh" {
  description = "Allow SSH access"
  type        = bool
  default     = false
}

variable "allow_web" {
  description = "Allow HTTP/HTTPS access"
  type        = bool
  default     = false
}

variable "ssh_source_ip" {
  description = "Source IP for SSH (use private network or bastion)"
  type        = string
  default     = "0.0.0.0/0" # Restrict in production!
}

variable "inbound_rules" {
  description = "Custom inbound rules"
  type = list(object({
    action = string
    port   = optional(string)
    ip     = optional(string)
  }))
  default = []
}

variable "outbound_rules" {
  description = "Custom outbound rules"
  type = list(object({
    action = string
    port   = optional(string)
    ip     = optional(string)
  }))
  default = []
}
