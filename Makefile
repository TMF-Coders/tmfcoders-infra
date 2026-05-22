# Makefile - TMF Coders Infrastructure (Scaleway, multi-tenant)
# Landing zone + per-tenant layered Terraform.

.PHONY: help fmt validate lint security check \
        bootstrap-init bootstrap-apply bootstrap-migrate \
        tp-init tp-apply tp-output \
        tenant-init tenant-plan tenant-apply tenant-destroy tenant-output \
        tenant-apply-all rebill clean

TENANT ?= tmf-internal
ENV    ?= prod
LAYER  ?= 1-org

ALL_LAYERS  := 1-org 2-network 3-apps 4-observability
ROOT_DIRS   := 0-bootstrap tenant-provisioning $(ALL_LAYERS)
TVARS_DIR    = $(PWD)/tenants/$(TENANT)/$(ENV)

help: ## Show this help
	@echo "TMF Coders - Infrastructure (Scaleway, multi-tenant)"
	@echo ""
	@echo "Usage: make <target> [TENANT=<t>] [ENV=dev|prod] [LAYER=<layer>]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Quality gate ────────────────────────────────────────────
fmt: ## Format all Terraform code
	terraform fmt -recursive .

validate: ## Validate every root (no backend)
	@for d in $(ROOT_DIRS); do \
		echo "validate $$d"; \
		terraform -chdir=$$d init -backend=false >/dev/null && \
		terraform -chdir=$$d validate || exit 1; \
	done

lint: ## Run tflint across the repo
	tflint --init
	tflint --recursive --config="$(PWD)/.tflint.hcl"

security: ## Run tfsec
	tfsec . --config-file .tfsec.yml --minimum-severity HIGH

check: fmt validate lint security ## Run the full local quality gate

# ── Landing zone (run once per Organization) ────────────────
bootstrap-init: ## Init landing-zone bootstrap on local state
	terraform -chdir=0-bootstrap init

bootstrap-apply: ## Apply landing zone (state bucket + CI IAM + platform project)
	terraform -chdir=0-bootstrap apply

bootstrap-migrate: ## Migrate bootstrap state into the remote bucket
	terraform -chdir=0-bootstrap init -migrate-state -backend-config=backend.hcl

# ── Tenant provisioning (Project-mode tenant projects) ──────
tp-init: ## Init tenant-provisioning
	terraform -chdir=tenant-provisioning init -backend-config=backend.hcl

tp-apply: ## Create/update Project-mode tenant projects
	terraform -chdir=tenant-provisioning apply

tp-output: ## Show tenant project IDs
	terraform -chdir=tenant-provisioning output

# ── Per-tenant layer operations ─────────────────────────────
# Backend + var-file are selected from tenants/<TENANT>/<ENV>/<LAYER>.*
tenant-init: ## Init a layer for a tenant (TENANT, ENV, LAYER)
	terraform -chdir=$(LAYER) init -reconfigure \
		-backend-config=$(TVARS_DIR)/$(LAYER).backend.hcl

tenant-plan: ## Plan a layer for a tenant (TENANT, ENV, LAYER)
	terraform -chdir=$(LAYER) plan -var-file=$(TVARS_DIR)/$(LAYER).tfvars

tenant-apply: ## Apply a layer for a tenant (TENANT, ENV, LAYER)
	terraform -chdir=$(LAYER) apply -var-file=$(TVARS_DIR)/$(LAYER).tfvars

tenant-destroy: ## Destroy a layer for a tenant (TENANT, ENV, LAYER)
	terraform -chdir=$(LAYER) destroy -var-file=$(TVARS_DIR)/$(LAYER).tfvars

tenant-output: ## Show outputs of a layer for a tenant (TENANT, ENV, LAYER)
	terraform -chdir=$(LAYER) output

tenant-apply-all: ## Init+apply every layer for a tenant, in order (TENANT, ENV)
	@for l in $(ALL_LAYERS); do \
		echo "=== $(TENANT)/$(ENV) :: $$l ==="; \
		terraform -chdir=$$l init -reconfigure -backend-config=$(TVARS_DIR)/$$l.backend.hcl && \
		terraform -chdir=$$l apply -auto-approve -var-file=$(TVARS_DIR)/$$l.tfvars || exit 1; \
	done

# ── Billing ─────────────────────────────────────────────────
rebill: ## Generate the monthly per-tenant cost report
	bash scripts/rebill.sh

clean: ## Remove local Terraform caches
	find . -type d -name ".terraform" | xargs -r rm -rf
	find . -type f -name "*.tfplan" -delete
	@echo "clean done"
