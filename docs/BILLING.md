# Billing & Cost Segmentation - TMF Coders Infrastructure

How costs are segmented per tenant on Scaleway and how to rebill clients.

## Scaleway billing facts

- The **invoice** is issued per **Organization**, not per Project.
- **Consumption** is reported per **Project**, per product, per resource.
- Billing API: `GET /billing/v2beta1/consumptions` - filterable by `project_id`.
- There is no native "per-project invoice" - chargeback is done by the operator.

## Hybrid model

| Tenant kind | Where it lives | `billing_mode` | Who pays Scaleway |
|-------------|----------------|----------------|-------------------|
| Platform / landing zone | Platform Project, home Org | n/a (`billable:false`) | TMF Coders |
| TMF internal workloads | Project in home Org | `project` | TMF Coders |
| Small / temporary client | Project in home Org | `project` | TMF Coders, rebills |
| Client as legal entity | Its own Organization | `org` | The client, directly |

- **Project-mode**: one Scaleway Project per tenant/environment, created by
  `tenant-provisioning`. Native per-project cost breakdown. TMF Coders pays the
  single Org invoice and rebills each client.
- **Org-mode**: the client owns a separate Organization. Run `0-bootstrap`
  against that Organization. The client receives its own Scaleway invoice;
  TMF Coders operates via delegated IAM access.

## Cost attribution

Every resource is tagged:

| Tag | Meaning |
|-----|---------|
| `tenant` | Tenant short name |
| `cost-center` | Chargeback cost center |
| `billing-mode` | `project` or `org` |
| `billable` | `true` for tenants, `false` for shared landing zone |
| `environment` | `dev` / `prod` / `landing-zone` |

The landing zone (`0-bootstrap`) is tagged `billable:false` - shared overhead,
either absorbed or spread across clients as a management fee.

## Monthly rebill

```bash
export SCW_SECRET_KEY="..."
export SCW_DEFAULT_ORGANIZATION_ID="..."
export REBILL_MARKUP_PCT="15"        # optional markup
make rebill
```

`scripts/rebill.sh` calls the Billing API, groups consumption by `project_id`,
applies the markup and prints a per-project cost table. Map `project_id` to a
tenant with `make tp-output`, then invoice each client.

For **Org-mode** clients, run the script with that Organization's credentials -
or let the client read their own Scaleway invoice directly.

## Onboarding a new tenant

Project-mode:
```bash
# 1. Add the tenant to tenant-provisioning/terraform.tfvars, then:
make tp-apply
make tp-output                       # note the new project_id

# 2. Scaffold the tenant's layer configs:
scripts/new-tenant.sh <tenant> prod project <cost-center> \
  <project_id> <state_bucket> <suffix> <alert_email>

# 3. Deploy:
make tenant-apply-all TENANT=<tenant> ENV=prod
```

Org-mode:
```bash
# 1. Get API credentials for the client's Organization.
# 2. Run 0-bootstrap against that Organization (its own state bucket).
# 3. scripts/new-tenant.sh <tenant> prod org ... (point state_bucket at the
#    client Org bucket), then make tenant-apply-all.
```
