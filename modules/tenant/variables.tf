variable "tenant" {
  description = "Tenant short name"
  type        = string
}

variable "project_name" {
  description = "Name of the Scaleway project for this tenant/environment"
  type        = string
}

variable "description" {
  description = "Project description"
  type        = string
  default     = ""
}

variable "create_client_access" {
  description = "Create a scoped IAM application giving the client access to their own project"
  type        = bool
  default     = false
}

variable "client_permission_sets" {
  description = "Permission sets granted to the client IAM application (must share one scope type)"
  type        = list(string)
  default     = ["AllProductsReadOnly"]
}
