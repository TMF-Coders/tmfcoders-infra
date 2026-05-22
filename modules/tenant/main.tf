/**
 * Tenant Module - Scaleway
 * Provisions one isolated Project for a Project-mode tenant inside the home
 * Organization. Scaleway bills consumption per Project, so a Project is the
 * unit of cost segregation and chargeback.
 *
 * Optionally creates a scoped IAM application granting the client read access
 * to their own Project (delegated visibility, never cross-tenant).
 */

resource "scaleway_account_project" "this" {
  name        = var.project_name
  description = var.description
}

#───────────────────────────────────────────────
# Optional: scoped client access to their own project
#───────────────────────────────────────────────
resource "scaleway_iam_application" "client" {
  count = var.create_client_access ? 1 : 0

  name        = "${var.project_name}-client-access"
  description = "Delegated client access for tenant ${var.tenant}"
}

resource "scaleway_iam_policy" "client" {
  count = var.create_client_access ? 1 : 0

  name           = "${var.project_name}-client-policy"
  description    = "Read-only access scoped to the tenant's own project"
  application_id = scaleway_iam_application.client[0].id

  rule {
    project_ids          = [scaleway_account_project.this.id]
    permission_set_names = var.client_permission_sets
  }
}

resource "scaleway_iam_api_key" "client" {
  count = var.create_client_access ? 1 : 0

  application_id     = scaleway_iam_application.client[0].id
  description        = "Client API key for tenant ${var.tenant}"
  default_project_id = scaleway_account_project.this.id
}
