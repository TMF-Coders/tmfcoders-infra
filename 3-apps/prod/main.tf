/**
 * Apps Layer - Production Environment (Scaleway)
 * Deploys OpenClaw (Matriz) and Odoo 17 (Filial)
 * Equivalent to GCP 3-apps layer
 */

terraform {
  required_version = ">= 1.5"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket   = "tmfcoders-terraform-state"
    key      = "3-apps/prod/terraform.tfstate"
    region   = "fr-par"
    endpoint = "s3.fr-par.scw.cloud"
    
    # Scaleway S3 credentials via environment variables:
    # export AWS_ACCESS_KEY_ID="SCWXXXXXXXXXXXXXX"
    # export AWS_SECRET_ACCESS_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    # export AWS_DEFAULT_REGION="fr-par"
  }
}

provider "scaleway" {}

locals {
  environment = "prod"
  region      = "fr-par" # Paris (GDPR - EU)
  zone        = "fr-par-1"
  
  common_labels = {
    environment  = local.environment
    managed_by   = "terraform"
    organization = "tmfcoders"
  }
}

#═══════════════════════════════════════
# VM 1: OpenClaw (TMF Coders - Matriz)
#═══════════════════════════════════════

module "openclaw" {
  source = "../../modules/instance"

  instance_name = "tmf-openclaw-${local.environment}-001"
  instance_type = "DEV1-M" # Equivalent to e2-standard-2
  image_id      = "ubuntu_jammy" # Ubuntu 22.04 LTS
  
  security_group_id = module.security_group_apps.id
  
  # Private network only (GDPR compliant)
  private_networks = [
    {
      pn_id  = var.tmf_network_id
      pnic_id = var.tmf_pnic_id
    }
  ]
  
  # NO public IP (equivalent to gcp disableExternalIpAccess policy)
  assign_public_ip = false
  
  tags = ["openclaw", "matriz", "allow-iap-ssh"]
  
  # Startup script for OpenClaw dependencies
  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update
    apt-get upgrade -y
    
    # Install dependencies for OpenClaw
    apt-get install -y \
      git \
      build-essential \
      cmake \
      libsdl2-dev \
      libsdl2-mixer-dev \
      libsdl2-image-dev \
      libsdl2-ttf-dev
    
    # Create app directory
    mkdir -p /opt/openclaw
    
    echo "OpenClaw VM initialized at $(date)" >> /var/log/startup.log
  USERDATA
}

#═══════════════════════════════════════
# VM 2: Odoo 17 (Filial - TMF Coders)
#═══════════════════════════════════════

module "odoo" {
  source = "../../modules/instance"

  instance_name = "tmf-odoo-${local.environment}-001"
  instance_type = "GP1-M" # Equivalent to e2-standard-4 (more RAM)
  image_id      = "ubuntu_jammy"
  
  security_group_id = module.security_group_apps.id
  
  private_networks = [
    {
      pn_id  = var.apps_network_id
      pnic_id = var.apps_pnic_id
    }
  ]
  
  # NO public IP (use Load Balancer for production)
  assign_public_ip = false
  
  root_volume_size = 100 # Larger disk for Odoo + PostgreSQL
  root_volume_type = "bssd" # Balanced SSD
  
  tags = ["odoo", "filial", "odoo-server"]
  
  # Comprehensive Odoo 17 installation script
  user_data = <<-USERDATA
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib
    
    # Install Python and dependencies
    apt-get install -y \
      python3-pip \
      python3-dev \
      python3-venv \
      libxml2-dev \
      libxslt1-dev \
      libldap2-dev \
      libsasl2-dev \
      libtiff5-dev \
      libjpeg-dev \
      libopenjp2-7-dev \
      zlib1g-dev \
      libfreetype6-dev \
      liblcms2-dev \
      libwebp-dev \
      libfribidi-dev \
      libxcb1-dev \
      libpq-dev \
      wget \
      git \
      nodejs \
      npm
    
    # Install wkhtmltopdf (for PDF reports)
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
    apt-get install -y ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb
    rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb
    
    # Create Odoo system user
    useradd -m -U -r -d /opt/odoo -s /bin/bash odoo
    
    # Create directories
    mkdir -p /opt/odoo/{odoo-server,custom-addons}
    chown -R odoo:odoo /opt/odoo
    
    # Clone Odoo (version 17.0 - latest LTS)
    su - odoo -c "git clone --depth 1 --branch 17.0 https://github.com/odoo/odoo.git /opt/odoo/odoo-server"
    
    # Create Python virtual environment
    su - odoo -c "/opt/odoo/venv/bin/pip install --upgrade pip"
    su - odoo -c "/opt/odoo/venv/bin/pip install -r /opt/odoo/odoo-server/requirements.txt"
    
    # Configure PostgreSQL
    sudo -u postgres createuser -s odoo
    
    # Create Odoo configuration file
    cat > /etc/odoo.conf <<EOF
[options]
admin_passwd = ChangeMe123!
db_host = localhost
db_port = 5432
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo-server/addons,/opt/odoo/custom-addons
logfile = /var/log/odoo/odoo.log
xmlrpc_port = 8069
longpolling_port = 8072
EOF
    
    chown odoo:odoo /etc/odoo.conf
    chmod 640 /etc/odoo.conf
    
    # Create log directory
    mkdir -p /var/log/odoo
    chown odoo:odoo /var/log/odoo
    
    # Create systemd service
    cat > /etc/systemd/system/odoo.service <<EOF
[Unit]
Description=Odoo ERP
After=network.target postgresql.service

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=/opt/odoo/venv/bin/python3 /opt/odoo/odoo-server/odoo-bin -c /etc/odoo.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start Odoo service
    systemctl daemon-reload
    systemctl enable odoo
    systemctl start odoo
    
    echo "Odoo installation completed at $(date)" >> /var/log/startup.log
    echo "Access Odoo at http://$(hostname -I | awk '{print \$1}'):8069" >> /var/log/startup.log
  USERDATA
}

#═══════════════════════════════════════
# SECURITY GROUP (Equivalent to IAM + Org Policies)
#═══════════════════════════════════════

module "security_group_apps" {
  source = "../../modules/security-group"

  security_group_name = "tmf-apps-${local.environment}"
  description       = "Security group for apps (OpenClaw + Odoo)"
  
  # RESTRICTIVE: Default drop (equivalent to Organization Policies)
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  
  # NO direct SSH from internet (use bastion or VPN)
  allow_ssh = false
  
  # NO direct web access (use Load Balancer)
  allow_web = false
  
  # Internal communication only (private networks)
  inbound_rules = [
    {
      action = "accept"
      port   = "22"
      ip     = "10.10.0.0/16" # Private network only
    },
    {
      action = "accept"
      port   = "8069" # Odoo HTTP
      ip     = "10.10.20.0/24" # Apps subnet
    },
    {
      action = "accept"
      port   = "8072" # Odoo longpolling
      ip     = "10.10.20.0/24"
    }
  ]
}

#═══════════════════════════════════════
# OUTPUTS
#═══════════════════════════════════════

output "openclaw_instance_id" {
  description = "OpenClaw instance ID"
  value       = module.openclaw.instance_id
}

output "openclaw_private_ip" {
  description = "OpenClaw private IP"
  value       = module.openclaw.private_ip
}

output "odoo_instance_id" {
  description = "Odoo instance ID"
  value       = module.odoo.instance_id
}

output "odoo_private_ip" {
  description = "Odoo private IP"
  value       = module.odoo.private_ip
}

output "ssh_command_openclaw" {
  description = "SSH command (via bastion or VPN)"
  value       = "ssh admin@${module.openclaw.private_ip}"
}

output "ssh_command_odoo" {
  description = "SSH command (via bastion or VPN)"
  value       = "ssh admin@${module.odoo.private_ip}"
}

output "odoo_web_url" {
  description = "Odoo web interface (internal)"
  value       = "http://${module.odoo.private_ip}:8069"
}
