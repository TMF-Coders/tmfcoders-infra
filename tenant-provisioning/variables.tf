variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "tenant_projects" {
  description = <<-DESC
    Map of Project-mode tenant/environment projects to create in the home
    Organization. Key is a unique slug (e.g. "acme-prod"). Org-mode tenants
    are deployed in their own Organization and must NOT be listed here.
  DESC
  type = map(object({
    tenant                 = string
    project_name           = string
    description            = optional(string, "")
    create_client_access   = optional(bool, false)
    client_permission_sets = optional(list(string), ["ProjectReadOnly", "BillingReadOnly"])
  }))
  default = {}
}
