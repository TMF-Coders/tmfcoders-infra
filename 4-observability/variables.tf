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

variable "alert_email" {
  description = "Email address that receives Cockpit alerts"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "audit_retention_days" {
  description = "Immutable retention for audit logs in Object Storage (GDPR: 730 days)"
  type        = number
  default     = 730

  validation {
    condition     = var.audit_retention_days >= 365 && var.audit_retention_days <= 3650
    error_message = "audit_retention_days must be between 365 and 3650."
  }
}

variable "cockpit_retention_days" {
  description = "Retention for Cockpit logs/metrics sources in days"
  type        = number
  default     = 31

  validation {
    condition     = var.cockpit_retention_days >= 1 && var.cockpit_retention_days <= 365
    error_message = "cockpit_retention_days must be between 1 and 365."
  }
}

variable "state_bucket_suffix" {
  description = "Globally-unique suffix for the audit log bucket"
  type        = string
}
