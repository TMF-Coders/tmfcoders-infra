#!/bin/bash
# Scaffold a new tenant environment from tenants/_template.
# Usage:
#   scripts/new-tenant.sh <tenant> <env> <billing_mode> <cost_center> \
#                         <project_id> <state_bucket> <suffix> <alert_email>
set -euo pipefail

if [ "$#" -ne 8 ]; then
  echo "Usage: $0 <tenant> <env> <billing_mode> <cost_center> <project_id> <state_bucket> <suffix> <alert_email>"
  echo "  billing_mode: project | org"
  exit 1
fi

TENANT="$1"; ENV="$2"; MODE="$3"; CC="$4"
PROJECT_ID="$5"; BUCKET="$6"; SUFFIX="$7"; EMAIL="$8"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${REPO_ROOT}/tenants/_template/prod"
DST="${REPO_ROOT}/tenants/${TENANT}/${ENV}"

if [ -d "$DST" ]; then
  echo "ERROR: $DST already exists"; exit 1
fi

mkdir -p "$DST"
cp "$SRC"/* "$DST"/

for f in "$DST"/*; do
  sed -i '' \
    -e "s/__TENANT__/${TENANT}/g" \
    -e "s/__ENV__/${ENV}/g" \
    -e "s/__BILLING_MODE__/${MODE}/g" \
    -e "s/__COST_CENTER__/${CC}/g" \
    -e "s/__PROJECT_ID__/${PROJECT_ID}/g" \
    -e "s/__BUCKET__/${BUCKET}/g" \
    -e "s/__SUFFIX__/${SUFFIX}/g" \
    -e "s/__ALERT_EMAIL__/${EMAIL}/g" \
    "$f"
done

echo "Created tenant environment: $DST"
echo "Review the .tfvars, then: make tenant-apply TENANT=${TENANT} ENV=${ENV}"
