# TMF Coders - Infrastructure as Code

> Infrastructure as Code (IaC) for TMF Coders using Terraform and Scaleway Cloud

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-623CE4?logo=terraform)](https://www.terraform.io/)
[![Scaleway](https://img.shields.io/badge/Scaleway-Cloud-EF3125?logo=scaleway)](https://www.scaleway.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github)](https://github.com/TMFCoders/tmfcoders-infra/actions)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)]()
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

## 📋 Table of Contents

- [Description](#-description)
- [Architecture](#-architecture)
- [Scaleway vs GCP Comparison](#-scaleway-vs-gcp-comparison)
- [Quick Start](#-quick-start)
- [Repository Structure](#-repository-structure)
- [Deployment Guide](#-deployment-guide)
- [Useful Commands](#-useful-commands)
- [Security](#-security)
- [Observability](#-observability)
- [Maintenance](#-maintenance)
- [Support](#-support)

## 🎯 Description

This repository contains **enterprise-grade infrastructure** for **TMF Coders** implemented with Terraform and Scaleway Cloud.

### 🏗️ Implemented Layers (5 Total)

| Layer | Component | Status |
|------|-----------|--------|
| **0-bootstrap** | Foundation: S3 bucket for Terraform state | ✅ |
| **1-org** | Structure + Security Groups + API Keys (equivalent to Org Policies + IAM) | ✅ |
| **2-network** | Private Networks + Public Gateway (equivalent to Shared VPC + Cloud NAT) | ✅ |
| **3-apps** | OpenClaw (Matriz) + Odoo 17 ERP (Filial) | ✅ |
| **4-observability** | CockroachDB logs + Audit (equivalent to Logs + Audit) | ✅ |
| **5-cicd** | Pipeline Quality Gate (fmt, linter, security) | ✅ |

### 🌍 Why Scaleway?

- ✅ **GDPR Compliant by Design** - European cloud provider
- ✅ **EU Regions Only** - Paris (fr-par), Amsterdam (nl-ams)
- ✅ **Cost Effective** - Up to 50% cheaper than hyperscalers
- ✅ **Full API Compatibility** - S3, Terraform-native
- ✅ **No Data Transfer** - All data stays in EU

---

## 🏗️ Architecture

### Scaleway Cloud Structure

```
TMF Coders Organization
│
└── Main Project (tmfcoders-infra)
    ├── Production/
    │   ├── Private Network: tmf-private-network-prod
    │   │   ├── Subnet: tmf-coders (10.10.10.0/24)
    │   │   └── VM: tmf-openclaw-prod-001
    │   │
    │   ├── Private Network: tmf-apps-prod
    │   │   ├── Subnet: apps (10.10.20.0/24)
    │   │   └── VM: tmf-odoo-prod-001 (Odoo 17 + PostgreSQL)
    │   │
    │   ├── Public Gateway (NAT) - tmf-nat-gateway-prod
    │   │
    │   └── 4-observability/
    │       ├── CockroachDB Cluster (audit logs - 730 days)
    │       └── Security Groups (restrictive)
    │
    └── Development/
        ├── Private Networks (same structure)
        └── 4-observability/ (365 days retention)
```

### 🔐 Security Implemented

**Security Groups (Equivalent to GCP Organization Policies + IAM):**
- ✅ **Default DROP** inbound (equivalent to `compute.disableExternalIpAccess`)
- ✅ **Private Networks Only** - No public IPs (GDPR)
- ✅ **SSH via Private Network** - No direct internet access
- ✅ **IAM via API Keys** - No Service Account keys (simpler than GCP WIF)

**Scaleway vs GCP Security Mapping:**

| Security Feature | GCP | Scaleway |
|---------|-----|----------|
| **Organization Policies** | 7 policies (PROD) | Security Groups (default DROP) |
| **Disable Public IPs** | `compute.disableExternalIpAccess` | Security Group rule |
| **IAM** | Service Accounts + WIF | API Keys + Security Groups |
| **Secret Manager** | Secret Manager | Environment variables (for now) |
| **No JSON Keys** | WIF (OIDC) | API Keys (simpler, EU-only) |

---

## 🌍 Scaleway vs GCP Comparison

### Layer-by-Layer Mapping

| Layer | GCP Component | Scaleway Equivalent | Differences |
|------|---------------|-------------------|-------------|
| **0-bootstrap** | GCS bucket | S3 bucket (Scaleway Object Storage) | S3 API compatibility ✅ |
| **1-org** | Organization + Folders + Projects | Project + Security Groups | Simpler hierarchy ✅ |
| | Org Policies (7 in PROD) | Security Groups (default DROP) | More restrictive by default ✅ |
| | IAM Service Accounts | API Keys | No WIF needed (simpler) ✅ |
| **2-network** | Shared VPC + Subnets | Private Networks + DHCP | Per-instance networks (not shared) ⚠️ |
| | Cloud NAT + Router | Public Gateway (NAT) | Automatic NAT ✅ |
| | Firewall Rules | Security Group Rules | Stateful firewall ✅ |
| **3-apps** | Compute Engine VMs | Instance Servers | Same concepts ✅ |
| | OS Login + IAP | SSH Keys + Private Network | Use bastion or VPN ⚠️ |
| **4-observability** | Log Sinks + Audit Logs | CockroachDB + Logs | Different tech stack ⚠️ |
| | Budget Alerts | Console Billing | Manual setup (no API) ⚠️ |
| **5-cicd** | GitHub Actions (WIF) | GitHub Actions (API Keys) | API keys in secrets ✅ |

### 🎯 Key Differences

#### ✅ Advantages of Scaleway
1. **GDPR Native** - All data stays in EU by default
2. **Simpler Security** - Security Groups vs GCP's complex Org Policies
3. **Cost** - Up to 50% cheaper than GCP
4. **S3 Compatibility** - Easy migration from AWS/GCP
5. **No WIF Needed** - API keys are simpler (but less secure than GCP WIF)

#### ⚠️ Limitations vs GCP
1. **No Shared VPC** - Each instance gets its own private network
2. **No Organization Policies** - Security Groups are per-resource, not hierarchical
3. **No Built-in Budget API** - Must use Console for billing alerts
4. **No Data Access Logs** - CockroachDB has query logs, but not equivalent to GCP's `DATA_READ`
5. **Less Enterprise Features** - Scaleway is simpler, which can be good or bad

---

## 🚀 Quick Start

### Prerequisites

```bash
# Verify tools
terraform --version  # >= 1.5 required
scw --version        # Scaleway CLI

# Authenticate with Scaleway
scw init              # Interactive setup
# OR via environment:
export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXX"
export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export SCW_DEFAULT_PROJECT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export SCW_DEFAULT_REGION="fr-par"      # Paris (EU)
export SCW_DEFAULT_ZONE="fr-par-1"

# Get Project ID
scw account project list
```

### Deployment (5 Minutes)

```bash
# 1. Clone repository
git clone https://github.com/TMFCoders/tmfcoders-infra.git
cd tmfcoders-infra

# 2. Initialize configuration
./init.sh
# Enter: Project ID, Region (fr-par)

# 3. Bootstrap (run ONCE)
cd 0-bootstrap
terraform init
terraform apply
cd ..

# 4. Deploy full production environment
make deploy-prod

# 5. Verify
make output-all ENV=prod
```

---

## 📁 Repository Structure

```
tmfcoders-infra/
├── 📘 README.md                  # This file
├── 📐 ARCHITECTURE.md            # Detailed diagrams
├── ⚡ QUICK_START.md             # Step-by-step guide
├── 🔧 Makefile                   # Automated commands
├── 🚀 init.sh                    # Initialization script
│
├── 0-bootstrap/                  # Initialization (S3 bucket)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── 1-org/                        # Organization + Security
│   ├── prod/
│   │   ├── main.tf              # Project + Security Groups
│   │   └── variables.tf
│   └── dev/
│
├── 2-network/                    # Private Networks + NAT
│   ├── prod/
│   │   ├── main.tf              # Private Networks + Public Gateway
│   │   └── variables.tf
│   └── dev/
│
├── 3-apps/                       # Application VMs
│   ├── prod/
│   │   ├── main.tf              # OpenClaw + Odoo 17 VMs
│   │   └── variables.tf
│   └── dev/
│
├── 4-observability/              # Logs + Audit
│   ├── prod/
│   │   ├── main.tf              # CockroachDB (730 days)
│   │   └── variables.tf
│   └── dev/
│
├── 5-cicd/                       # CI/CD Pipeline
│   └── .github/workflows/
│       └── terraform-ci.yml
│
└── modules/                      # Reusable Terraform modules
    ├── project/                  # Scaleway Project
    ├── security-group/          # Security Groups (equivalent to IAM + Firewall)
    └── instance/                # Instance Servers (equivalent to Compute Engine)
```

---

## 📖 Deployment Guide

### Step 1: Bootstrap (Run ONCE)

Creates S3 bucket for Terraform remote state:

```bash
cd 0-bootstrap
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars:
# project_name = "tmfcoders-infra"
# region = "fr-par"

terraform init
terraform plan
terraform apply
```

### Step 2: Organization & Security

Creates project and security groups:

```bash
cd ../1-org/prod

# Edit terraform.tfvars:
# project_name = "TMF Coders - PROD"

terraform init
terraform plan
terraform apply
```

### Step 3: Network (Private Networks + NAT)

Configures private networks and NAT gateway:

```bash
cd ../../2-network/prod

terraform init
terraform plan
terraform apply
```

### Step 4: Applications

Deploys VMs:

```bash
cd ../../3-apps/prod

terraform init
terraform plan
terraform apply
```

**Resources Created:**
- ✅ VM OpenClaw (Matriz) - Debian/Ubuntu
- ✅ VM Odoo 17 (Filial) - Ubuntu + PostgreSQL + Odoo 17

---

## 🛠️ Useful Commands

```bash
# See all commands
make help

# Deploy complete production
make deploy-prod

# SSH to VMs (via private network/bastion)
# Note: Scaleway doesn't have IAP - use bastion or VPN
ssh admin@PRIVATE_IP

# Verify Odoo
make ssh-odoo ENV=prod
sudo systemctl status odoo
sudo tail -f /var/log/odoo/odoo.log

# Validate all
make validate
make fmt
```

---

## 🔐 Security

### Scaleway Security Model

**1. API Keys (Equivalent to GCP Service Accounts)**
- ✅ **Simple**: Just set environment variables
- ✅ **EU-Only**: No data leaves European servers
- ⚠️ **Less Secure than GCP WIF**: API keys don't expire automatically

**2. Security Groups (Equivalent to Organization Policies + Firewall)**
- ✅ **Default DROP**: All inbound traffic blocked by default
- ✅ **Stateful**: Return traffic automatically allowed
- ✅ **Per-Resource**: Attach to instances (not hierarchical like GCP)

**3. Private Networks (Equivalent to Shared VPC)**
- ✅ **Isolation**: Each instance can have its own network
- ⚠️ **No Shared VPC**: Can't share networks between "projects" (use Security Groups instead)
- ✅ **NAT Gateway**: Automatic outbound internet via Public Gateway

### Security Groups Configuration

| Rule Type | GCP Equivalent | Configuration |
|-----------|---------------|----------------|
| **Default Inbound** | `compute.disableExternalIpAccess` | DROP all |
| **SSH Access** | IAP + OS Login | Allow from private network only |
| **Web Access** | Firewall rules | Allow ports 80, 443 from specific IPs |
| **Outbound** | Cloud NAT | ACCEPT all (NAT handles it) |

---

## 🔭 Observability

### 3 Pillars Implemented

| Pillar | GCP Implementation | Scaleway Implementation | Status |
|--------|--------------------|--------------------------|--------|
| **Centralized Logs** | Log Sinks → GCS bucket (730 days) | CockroachDB cluster (730 days) | ✅ |
| **Deep Audit** | DATA_ACCESS logs (Admin + Data Read/Write) | CockroachDB query logging | ⚠️ Different |
| **Alerts** | Email + SMS (Org Policy violations, 403s, Budget) | Console only (no API) | ⚠️ Manual |

### Differences from GCP

**GCP:**
- Log sinks to centralized GCS bucket
- Data Access logs (reads + writes)
- Budget API for automated alerts
- Organization Policy violation alerts

**Scaleway:**
- CockroachDB for logs (query-level auditing)
- No built-in budget API (use Console)
- Manual alert setup in Scaleway Console
- No Organization Policies (use Security Groups)

---

## 🔧 Maintenance

### Update Machine Type

```bash
cd 3-apps/prod

# Edit main.tf:
# instance_type = "GP1-L"  # Larger instance

terraform plan
terraform apply  # VM will restart
```

### Add New VM

```bash
# Edit 3-apps/prod/main.tf
module "vm_new_app" {
  source = "../../modules/instance"
  
  instance_name = "tmf-new-app-prod-001"
  instance_type = "DEV1-M"
  security_group_id = module.security_group_apps.id
  
  private_networks = [
    {
      pn_id  = var.apps_network_id
      pnic_id = var.apps_pnic_id
    }
  ]
}
```

---

## 📞 Support

### Technical Documentation
- **Scaleway Docs**: https://www.scaleway.com/en/docs/
- **Terraform Scaleway Provider**: https://registry.terraform.io/providers/scaleway/scaleway/latest/docs

### Contact
- **Infrastructure Team**: infra@tmfcoders.com
- **Security Team**: security@tmfcoders.com

### Issues
Report problems or suggestions via GitHub Issues.

---

## 📄 License

**Proprietary - TMF Coders**

All rights reserved © 2026 TMF Coders.

---

**Maintained by**: Infrastructure Team @ TMF Coders  
**Last updated**: May 2026  
**Version**: 1.0.0

---

## 🎉 Complete Architecture Comparison

### Final Summary: GCP vs Scaleway

| Aspect | GCP Landing Zone | Scaleway Landing Zone |
|--------|-----------------|----------------------|
| **Complexity** | High (Org Policies, WIF, Shared VPC) | Medium (Security Groups, API Keys) |
| **GDPR** | Configured via policies | Native (EU-only) ✅ |
| **Cost** | Higher | Up to 50% cheaper ✅ |
| **Security** | Enterprise-grade (7 policies PROD) | Simpler (Security Groups) |
| **Observability** | Full (Logs + Audit + Alerts) | Partial (CockroachDB + Console) |
| **CI/CD** | GitHub Actions + WIF | GitHub Actions + API Keys |
| **Learning Curve** | Steep | Gentle ✅ |

**Bottom Line**: Scaleway is a **simpler, cheaper, GDPR-native** alternative to GCP. Perfect for European companies that want enterprise-grade infrastructure without the complexity. 🌍
