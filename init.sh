#!/bin/bash
# Initialisation helper for tmfcoders-infra (Scaleway, multi-tenant).
# Verifies prerequisites and scaffolds terraform.tfvars for the shared roots.
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo "========================================="
echo "TMF Coders - Infrastructure bootstrap"
echo "========================================="

# ── Prerequisites ───────────────────────────────────────────
command -v terraform >/dev/null 2>&1 \
  && echo -e "${GREEN}OK terraform: $(terraform version | head -n1)${NC}" \
  || { echo -e "${RED}ERROR: terraform not installed (>= 1.10 required)${NC}"; exit 1; }

command -v scw >/dev/null 2>&1 \
  && echo -e "${GREEN}OK scaleway-cli${NC}" \
  || echo -e "${YELLOW}WARN: scaleway-cli (scw) not installed - optional${NC}"

command -v jq >/dev/null 2>&1 \
  && echo -e "${GREEN}OK jq${NC}" \
  || echo -e "${YELLOW}WARN: jq not installed - needed by scripts/rebill.sh${NC}"

for v in SCW_ACCESS_KEY SCW_SECRET_KEY; do
  [ -z "${!v:-}" ] && echo -e "${YELLOW}WARN: $v is not exported${NC}"
done

# ── Scaffold tfvars for the shared roots ────────────────────
echo ""
echo "Scaffolding terraform.tfvars for shared roots (existing files kept)..."
for example in 0-bootstrap/terraform.tfvars.example tenant-provisioning/terraform.tfvars.example; do
  target="${example%.example}"
  if [ -f "$target" ]; then
    echo -e "${YELLOW}skip  $target${NC}"
  else
    cp "$example" "$target"
    echo -e "${GREEN}created  $target${NC}"
  fi
done

cat <<'EOF'

Next steps
----------
1. Export Scaleway credentials:
     export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
     export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
     export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"        # S3 backend
     export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"    # S3 backend

2. Landing zone (once per Organization):
     make bootstrap-apply
     # copy state bucket name into every backend.hcl, then:
     make bootstrap-migrate

3. Create Project-mode tenant projects:
     # edit tenant-provisioning/terraform.tfvars
     make tp-init && make tp-apply && make tp-output

4. Scaffold and deploy a tenant:
     scripts/new-tenant.sh <tenant> prod project <cost-center> \
       <project_id> <state_bucket> <suffix> <alert_email>
     make tenant-apply-all TENANT=<tenant> ENV=prod

See RUNBOOK.md for the full procedure and docs/BILLING.md for cost segmentation.
EOF
