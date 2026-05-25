variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "tenant" {
  description = "Tenant short name - billing/segmentation key"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.tenant))
    error_message = "tenant must be lowercase alphanumeric with hyphens."
  }
}

variable "cost_center" {
  description = "Cost center for billing attribution / chargeback"
  type        = string
}

variable "billing_mode" {
  description = "Billing model: 'project' (Project in home Org) or 'org' (separate Organization)"
  type        = string
  default     = "project"

  validation {
    condition     = contains(["project", "org"], var.billing_mode)
    error_message = "billing_mode must be 'project' or 'org'."
  }
}

variable "project_id" {
  description = "Scaleway project ID (tenant project)"
  type        = string
}

variable "region" {
  description = "Scaleway region (EU only)"
  type        = string
  default     = "fr-par"

  validation {
    condition     = contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "region must be an EU region: fr-par, nl-ams or pl-waw."
  }
}

variable "zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "state_bucket" {
  description = "Object Storage bucket holding remote state for cross-layer reads"
  type        = string
}

variable "enable_openclaw" {
  description = "Deploy the OpenClaw VM"
  type        = bool
  default     = true
}

variable "openclaw_instance_type" {
  description = "Instance type for the OpenClaw VM"
  type        = string
  default     = "PRO2-S"
}

variable "odoo_instance_type" {
  description = "Instance type for the Odoo VM"
  type        = string
  default     = "PRO2-M"
}

variable "rdb_node_type" {
  description = "Managed PostgreSQL node type"
  type        = string
  default     = "DB-GP-S"
}

variable "rdb_is_ha" {
  description = "Deploy the managed PostgreSQL as a High-Availability cluster"
  type        = bool
  default     = true
}

variable "rdb_backup_retention_days" {
  description = "Managed PostgreSQL automated backup retention in days"
  type        = number
  default     = 30
}

variable "rdb_volume_size_gb" {
  description = "Managed PostgreSQL volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.rdb_volume_size_gb >= 5 && var.rdb_volume_size_gb <= 10000
    error_message = "rdb_volume_size_gb must be between 5 and 10000."
  }
}

variable "odoo_domain" {
  description = "Public DNS name for the Odoo Load Balancer TLS certificate"
  type        = string
  default     = ""
}

variable "enable_odoo_load_balancer" {
  description = "Provision a public HTTPS Load Balancer in front of Odoo"
  type        = bool
  default     = true
}

variable "enable_power_schedule" {
  description = "Power the application VMs off/on on a schedule to save compute cost"
  type        = bool
  default     = true
}

variable "power_off_cron" {
  description = "UTC cron for powering VMs off (default 01:00 CET = 00:00 UTC)"
  type        = string
  default     = "0 0 * * *"
}

variable "power_on_cron" {
  description = "UTC cron for powering VMs on (default 09:00 CET = 08:00 UTC)"
  type        = string
  default     = "0 8 * * *"
}

variable "admin_ssh_keys" {
  description = "Public SSH keys injected into root's authorized_keys on every VM at first boot"
  type        = list(string)
  default     = []
}

variable "odoo_assign_public_ip" {
  description = "Attach a routed public IP to the Odoo VM (temporary - migration window only)"
  type        = bool
  default     = false
}

variable "admin_root_password" {
  description = "Optional root password for Scaleway serial console (sensitive, temporary)"
  type        = string
  sensitive   = true
  default     = ""
}
