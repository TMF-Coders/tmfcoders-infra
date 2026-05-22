variable "name_prefix" {
  description = "Prefix applied to all network resource names"
  type        = string
}

variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "region" {
  description = "Scaleway region (EU only for data residency)"
  type        = string
  default     = "fr-par"

  validation {
    condition     = contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "region must be an EU region: fr-par, nl-ams or pl-waw."
  }
}

variable "zone" {
  description = "Scaleway zone for zonal resources (public gateway)"
  type        = string
  default     = "fr-par-1"
}

variable "private_networks" {
  description = "Map of private networks to create (key = short name, value = subnet CIDR)"
  type = map(object({
    subnet = string
  }))

  validation {
    condition     = alltrue([for pn in var.private_networks : can(cidrhost(pn.subnet, 0))])
    error_message = "Each private network subnet must be a valid IPv4 CIDR."
  }
}

variable "enable_public_gateway" {
  description = "Create a Public Gateway for NAT egress and bastion access"
  type        = bool
  default     = true
}

variable "public_gateway_type" {
  description = "Public Gateway commercial type"
  type        = string
  default     = "VPC-GW-S"
}

variable "bastion_enabled" {
  description = "Enable the SSH bastion on the Public Gateway (no direct SSH from internet)"
  type        = bool
  default     = true
}

variable "bastion_port" {
  description = "TCP port exposed by the SSH bastion"
  type        = number
  default     = 61000
}

variable "tags" {
  description = "Tags applied to network resources"
  type        = list(string)
  default     = []
}
