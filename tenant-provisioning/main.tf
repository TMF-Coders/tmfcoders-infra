/**
 * Tenant Provisioning - Scaleway (home Organization)
 * Creates one Project per Project-mode tenant/environment. Each Project is an
 * independent billing unit; Org-mode tenants live in their own Organization
 * and are NOT managed here (run 0-bootstrap against that Organization instead).
 *
 * Runs in the home Organization with home credentials.
 */

module "tenant" {
  source   = "../modules/tenant"
  for_each = var.tenant_projects

  tenant                 = each.value.tenant
  project_name           = each.value.project_name
  description            = each.value.description
  create_client_access   = each.value.create_client_access
  client_permission_sets = each.value.client_permission_sets
}
