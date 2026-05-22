variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = ""
}

variable "project_id" {
  description = "Scaleway project ID the security group belongs to"
  type        = string
}

variable "inbound_default_policy" {
  description = "Default policy for inbound traffic (accept or drop)"
  type        = string
  default     = "drop"

  validation {
    condition     = contains(["accept", "drop"], var.inbound_default_policy)
    error_message = "inbound_default_policy must be 'accept' or 'drop'."
  }
}

variable "outbound_default_policy" {
  description = "Default policy for outbound traffic (accept or drop)"
  type        = string
  default     = "accept"

  validation {
    condition     = contains(["accept", "drop"], var.outbound_default_policy)
    error_message = "outbound_default_policy must be 'accept' or 'drop'."
  }
}

variable "inbound_rules" {
  description = "Inbound firewall rules. Use port for single ports, port_range for ranges."
  type = list(object({
    action     = optional(string, "accept")
    protocol   = optional(string, "TCP")
    port       = optional(number)
    port_range = optional(string)
    ip_range   = optional(string, "0.0.0.0/0")
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.inbound_rules : contains(["accept", "drop"], r.action)])
    error_message = "Each inbound rule action must be 'accept' or 'drop'."
  }
}

variable "outbound_rules" {
  description = "Outbound firewall rules"
  type = list(object({
    action     = optional(string, "accept")
    protocol   = optional(string, "TCP")
    port       = optional(number)
    port_range = optional(string)
    ip_range   = optional(string, "0.0.0.0/0")
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the security group"
  type        = list(string)
  default     = []
}
