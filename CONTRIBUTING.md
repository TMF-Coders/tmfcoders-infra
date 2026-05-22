# Contributing - TMF Coders Infrastructure

## Workflow

1. Branch from `master`: `feat/<topic>` or `fix/<topic>`.
2. Make changes; keep each layer self-contained.
3. Run the local quality gate before pushing:
   ```bash
   make check          # fmt + validate + tflint + tfsec
   ```
4. Open a pull request. The CI quality gate must pass:
   fmt/validate, tflint, tfsec, checkov, gitleaks, terraform-docs, infracost.
5. Squash-merge after review.

## Local setup

```bash
pip install pre-commit
pre-commit install
```

`pre-commit` runs fmt, validate, tflint, tfsec, terraform-docs and gitleaks on
every commit.

## Conventions

- `1-org`..`4-observability` are single canonical roots; a deployment is a
  *(tenant, environment)* pair selected via `backend.hcl` + `.tfvars` under
  `tenants/<tenant>/<env>/`.
- Never reach across state files except via `terraform_remote_state`
  (tenant-scoped by state key).
- All variables are typed and validated; EU-region-only is enforced.
- Resource names: `<tenant>-<env>-<workload>`. Locals/outputs: `snake_case`.
- Tenant `.tfvars` ARE committed — they carry no secrets, only the tenant
  inventory. `terraform.tfvars` for the shared roots, state files and
  credentials are never committed.
- Secrets are generated (`random_password`) and stored in Secret Manager —
  never placed in `.tfvars` or VM user-data in clear text.
- Every resource is tagged `tenant` / `cost-center` / `billing-mode` /
  `billable` for cost segmentation.
- `.terraform.lock.hcl` IS committed (provider pinning).

## Adding a resource

- Put reusable resources in `modules/`; layers only wire modules together.
- Update the module `README.md` (terraform-docs injects the inputs/outputs).
- Add outputs other layers need; consume them via `terraform_remote_state`.

## Commit messages

Conventional Commits: `feat(layer): ...`, `fix(module): ...`, `chore: ...`.
