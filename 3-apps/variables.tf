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
