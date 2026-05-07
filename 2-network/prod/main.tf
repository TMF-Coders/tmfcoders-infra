/**
 * Network Layer - Production Environment (Scaleway)
 * Equivalent to GCP 2-network layer
 * Creates private networks, subnets, and NAT gateway
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
    key      = "2-network/prod/terraform.tfstate"
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
  
  common_labels = {
    environment  = local.environment
    managed_by   = "terraform"
    organization = "tmfcoders"
  }
}

#═════════════════════════════════════════════
# PRIVATE NETWORK (Equivalent to Shared VPC)
#═════════════════════════════════════════════

resource "scaleway_vpc_private_network" "main" {
  name       = "tmf-private-network-${local.environment}"
  tags       = merge(local.common_labels, {
    purpose = "main-network"
  })
}

# Subnet for TMF Coders (Matriz)
resource "scaleway_vpc_private_network" "tmf" {
  name       = "tmf-coders-${local.environment}"
  tags       = merge(local.common_labels, {
    purpose    = "tmf-coders"
    business_unit = "matriz"
  })
}

# Subnet for Apps (Filial - equivalent to vc-apps)
resource "scaleway_vpc_private_network" "apps" {
  name       = "tmf-apps-${local.environment}"
  tags       = merge(local.common_labels, {
    purpose       = "apps"
    business_unit = "filial"
  })
}

#═════════════════════════════════════════════
# PUBLIC GATEWAY (Equivalent to Cloud NAT)
#═════════════════════════════════════════════

resource "scaleway_vpc_public_gateway" "nat" {
  name             = "tmf-nat-gateway-${local.environment}"
  tags             = merge(local.common_labels, {
    purpose = "nat-gateway"
  })
}

# Attach gateway to TMF network
resource "scaleway_vpc_gateway_network" "tmf" {
  gateway_id         = scaleway_vpc_public_gateway.nat.id
  private_network_id = scaleway_vpc_private_network.tmf.id
  dhcp_id            = scaleway_vpc_private_network.tmf.default_dhcp_id
}

# Attach gateway to Apps network
resource "scaleway_vpc_gateway_network" "apps" {
  gateway_id         = scaleway_vpc_public_gateway.nat.id
  private_network_id = scaleway_vpc_private_network.apps.id
  dhcp_id            = scaleway_vpc_private_network.apps.default_dhcp_id
}

#═════════════════════════════════════════════
# DHCP CONFIG (Equivalent to Subnet configuration)
#═════════════════════════════════════════════

# TMF Coders subnet: 10.10.10.0/24
resource "scaleway_vpc_dhcp" "tmf" {
  private_network_id = scaleway_vpc_private_network.tmf.id
  
  subnet {
    subnet  = "10.10.10.0/24"
    ip_range = "10.10.10.0/24"
  }
  
  tags       = merge(local.common_labels, {
    subnet = "tmf-coders"
  })
}

# Apps subnet: 10.10.20.0/24 (equivalent to vc-apps)
resource "scaleway_vpc_dhcp" "apps" {
  private_network_id = scaleway_vpc_private_network.apps.id
  
  subnet {
    subnet  = "10.10.20.0/24"
    ip_range = "10.10.20.0/24"
  }
  
  tags       = merge(local.common_labels, {
    subnet = "apps"
  })
}

#═════════════════════════════════════════════
# OUTPUTS
#═════════════════════════════════════════════

output "private_network_id" {
  description = "Main Private Network ID"
  value       = scaleway_vpc_private_network.main.id
}

output "tmf_network_id" {
  description = "TMF Coders Private Network ID"
  value       = scaleway_vpc_private_network.tmf.id
}

output "apps_network_id" {
  description = "Apps (Filial) Private Network ID"
  value       = scaleway_vpc_private_network.apps.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = scaleway_vpc_public_gateway.nat.id
}

output "tmf_subnet" {
  description = "TMF Coders subnet (10.10.10.0/24)"
  value       = "10.10.10.0/24"
}

output "apps_subnet" {
  description = "Apps subnet (10.10.20.0/24)"
  value       = "10.10.20.0/24"
}
