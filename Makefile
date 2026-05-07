# Makefile for TMF Coders Infrastructure
# Facilitates management of Terraform across multiple layers

.PHONY: help init-all plan-all apply-all bootstrap org-prod network-prod apps-prod

# Variables
ENV ?= prod
LAYER ?= all

help: ## Show this help
	@echo "TMF Coders - Infrastructure Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init-all: ## Initialize all layers (by environment)
	@echo "Initializing all layers for $(ENV)..."
	@make -C 0-bootstrap init
	@make -C 1-org/$(ENV) init
	@make -C 2-network/$(ENV) init
	@make -C 3-apps/$(ENV) init
	@make -C 4-observability/$(ENV) init

# Bootstrap
bootstrap-init: ## Init bootstrap layer
	cd 0-bootstrap && terraform init

bootstrap-plan: ## Plan bootstrap layer
	cd 0-bootstrap && terraform plan

bootstrap-apply: ## Apply bootstrap layer
	cd 0-bootstrap && terraform apply

bootstrap-destroy: ## Destroy bootstrap (CAUTION)
	cd 0-bootstrap && terraform destroy

# Organization
org-init: ## Init org layer
	cd 1-org/$(ENV) && terraform init

org-plan: ## Plan org layer
	cd 1-org/$(ENV) && terraform plan

org-apply: ## Apply org layer
	cd 1-org/$(ENV) && terraform apply

org-output: ## Show org outputs
	cd 1-org/$(ENV) && terraform output

# Network
network-init: ## Init network layer
	cd 2-network/$(ENV) && terraform init

network-plan: ## Plan network layer
	cd 2-network/$(ENV) && terraform plan

network-apply: ## Apply network layer
	cd 2-network/$(ENV) && terraform apply

network-output: ## Show network outputs
	cd 2-network/$(ENV) && terraform output

# Apps
apps-init: ## Init apps layer
	cd 3-apps/$(ENV) && terraform init

apps-plan: ## Plan apps layer
	cd 3-apps/$(ENV) && terraform plan

apps-apply: ## Apply apps layer
	cd 3-apps/$(ENV) && terraform apply

apps-output: ## Show apps outputs
	cd 3-apps/$(ENV) && terraform output

apps-destroy: ## Destroy apps (CAUTION)
	cd 3-apps/$(ENV) && terraform destroy

# Observability
obs-init: ## Init observability layer
	cd 4-observability/$(ENV) && terraform init

obs-plan: ## Plan observability layer
	cd 4-observability/$(ENV) && terraform plan

obs-apply: ## Apply observability layer
	cd 4-observability/$(ENV) && terraform apply

obs-output: ## Show observability outputs
	cd 4-observability/$(ENV) && terraform output

# Combined commands
plan-all: ## Plan all layers
	@make org-plan ENV=$(ENV)
	@make network-plan ENV=$(ENV)
	@make apps-plan ENV=$(ENV)
	@make obs-plan ENV=$(ENV)

apply-all: ## Apply all layers
	@make org-apply ENV=$(ENV)
	@make network-apply ENV=$(ENV)
	@make apps-apply ENV=$(ENV)
	@make obs-apply ENV=$(ENV)

output-all: ## Show all outputs
	@echo "=== Organization ==="
	@make org-output ENV=$(ENV)
	@echo ""
	@echo "=== Network ==="
	@make network-output ENV=$(ENV)
	@echo ""
	@echo "=== Apps ==="
	@make apps-output ENV=$(ENV)
	@echo ""
	@echo "=== Observability ==="
	@make obs-output ENV=$(ENV)

# Validation and formatting
validate: ## Validate Terraform syntax
	@echo "Validating syntax..."
	@for dir in 0-bootstrap 1-org/$(ENV) 2-network/$(ENV) 3-apps/$(ENV) 4-observability/$(ENV); do \
		echo "Validating $$dir..."; \
		cd $$dir && terraform validate && cd ..; \
	done

fmt: ## Format Terraform code
	@echo "Formatting code..."
	terraform fmt -recursive .

# State management
state-list: ## List resources in state
	cd 3-apps/$(ENV) && terraform state list

# SSH connections (Note: Scaleway doesn't have IAP - use bastion or VPN)
ssh-openclaw: ## Connect to OpenClaw VM
	@echo "OpenClaw SSH: Use private IP via bastion or VPN"
	@cd 3-apps/$(ENV) && terraform output ssh_command_openclaw

ssh-odoo: ## Connect to Odoo VM
	@echo "Odoo SSH: Use private IP via bastion or VPN"
	@cd 3-apps/$(ENV) && terraform output ssh_command_odoo

# Deployment shortcuts
deploy-prod: ## Deploy full production environment
	@echo "Deploying production environment..."
	@make bootstrap-apply
	@make org-apply ENV=prod
	@make network-apply ENV=prod
	@make apps-apply ENV=prod
	@make obs-apply ENV=prod
	@echo "Deployment complete!"

deploy-dev: ## Deploy full development environment
	@echo "Deploying development environment..."
	@make org-apply ENV=dev
	@make network-apply ENV=dev
	@make apps-apply ENV=dev
	@make obs-apply ENV=dev
	@echo "Deployment complete!"

# Cleanup
clean: ## Clean temporary files
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name ".terraform.lock.hcl" -delete
	find . -type f -name "*.tfstate.backup" -delete
	@echo "Cleanup complete"
