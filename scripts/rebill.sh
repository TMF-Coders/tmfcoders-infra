#!/bin/bash
# Monthly per-tenant cost report from the Scaleway Billing API.
# Groups consumption by Project (= billing segment) and applies a markup.
#
# Required env:
#   SCW_SECRET_KEY                  Scaleway API secret key
#   SCW_DEFAULT_ORGANIZATION_ID     Organization to report on
# Optional env:
#   REBILL_MARKUP_PCT               Markup percentage to apply (default 0)
set -euo pipefail

: "${SCW_SECRET_KEY:?Set SCW_SECRET_KEY}"
: "${SCW_DEFAULT_ORGANIZATION_ID:?Set SCW_DEFAULT_ORGANIZATION_ID}"
MARKUP="${REBILL_MARKUP_PCT:-0}"
API="https://api.scaleway.com/billing/v2beta1"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required"; exit 1; }

echo "Scaleway per-tenant cost report"
echo "Organization : $SCW_DEFAULT_ORGANIZATION_ID"
echo "Markup       : ${MARKUP}%"
echo "-------------------------------------------------------------"
printf "%-38s %12s %12s\n" "PROJECT_ID" "COST_EUR" "REBILL_EUR"
echo "-------------------------------------------------------------"

curl -fsS -H "X-Auth-Token: ${SCW_SECRET_KEY}" \
  "${API}/consumptions?organization_id=${SCW_DEFAULT_ORGANIZATION_ID}" \
| jq -r --arg markup "$MARKUP" '
    .consumptions
    | group_by(.project_id)
    | map({
        project: (.[0].project_id // "unattributed"),
        eur: (map((.value.units // 0) + ((.value.nanos // 0) / 1000000000)) | add)
      })
    | sort_by(-.eur)
    | .[]
    | [ .project,
        (.eur | . * 100 | round / 100),
        (.eur * (1 + ($markup | tonumber) / 100) | . * 100 | round / 100)
      ]
    | @tsv
' | while IFS=$'\t' read -r project cost rebill; do
  printf "%-38s %12s %12s\n" "$project" "$cost" "$rebill"
done

echo "-------------------------------------------------------------"
echo "Map PROJECT_ID to tenant with: make tp-output"
echo "Invoice each client their REBILL_EUR amount."
