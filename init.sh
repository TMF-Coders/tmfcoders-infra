#!/bin/bash
# Script de inicialización para el repositorio tmfcoders-infra

set -e

echo "========================================="
echo "TMF Coders - Inicialización"
echo "========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar prerrequisitos
echo "Verificando prerrequisitos..."

# Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}ERROR: Terraform no está instalado${NC}"
    echo "Instala Terraform desde: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform instalado: $(terraform version | head -n1)${NC}"

# Scaleway CLI
if ! command -v scw &> /dev/null; then
    echo -e "${YELLOW}ADVERTENCIA: Scaleway CLI no está instalado${NC}"
    echo "Instala scw desde: https://www.scaleway.com/en/docs/console/cli/"
    echo "O configura las variables de entorno: SCW_ACCESS_KEY, SCW_SECRET_KEY, etc."
else
    echo -e "${GREEN}✓ Scaleway CLI instalado${NC}"
fi

echo ""
echo "========================================="
echo "Configuración Inicial"
echo "========================================="
echo ""

# Solicitar información
read -p "Ingresa tu Project ID de Scaleway: " PROJECT_ID
read -p "Ingresa la región (ej: fr-par): " REGION
read -p "Ingresa la zona (ej: fr-par-1): " ZONE
read -p "Ingresa el sufijo para el bucket de estado: " BUCKET_SUFFIX

echo ""
echo "Creando archivos de configuración..."

# 0-bootstrap
cat > 0-bootstrap/terraform.tfvars << EOF
project_name = "TMF Coders - Infrastructure"
region       = "${REGION}"
bucket_suffix = "${BUCKET_SUFFIX}"
EOF
echo -e "${GREEN}✓ Creado: 0-bootstrap/terraform.tfvars${NC}"

# 1-org/prod
cat > 1-org/prod/terraform.tfvars << EOF
project_name = "TMF Coders - PROD"
region       = "${REGION}"
zone         = "${ZONE}"
EOF
echo -e "${GREEN}✓ Creado: 1-org/prod/terraform.tfvars${NC}"

# 2-network/prod
cat > 2-network/prod/terraform.tfvars << EOF
tmf_network_id  = "tmf-private-network-prod"
apps_network_id = "tmf-apps-prod"
nat_gateway_id  = "tmf-nat-gateway-prod"
EOF
echo -e "${GREEN}✓ Creado: 2-network/prod/terraform.tfvars${NC}"

# 3-apps/prod
cat > 3-apps/prod/terraform.tfvars << EOF
tmf_network_id  = "tmf-private-network-prod"
tmf_pnic_id     = "pn-xxxxxxxxxxxx"  # Update with real PNIC ID
apps_network_id = "tmf-apps-prod"
apps_pnic_id    = "pn-xxxxxxxxxxxx"  # Update with real PNIC ID
assign_public_ip = false  # Recommended for production
EOF
echo -e "${GREEN}✓ Creado: 3-apps/prod/terraform.tfvars${NC}"

# 4-observability/prod
cat > 4-observability/prod/terraform.tfvars << EOF
project_id    = "${PROJECT_ID}"
region        = "${REGION}"
retention_days = 730  # 2 years for GDPR
EOF
echo -e "${GREEN}✓ Creado: 4-observability/prod/terraform.tfvars${NC}"

echo ""
echo "========================================="
echo "Siguiente Paso: Bootstrap"
echo "========================================="
echo ""
echo "Ejecuta los siguientes comandos:"
echo ""
echo "  cd 0-bootstrap"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""
echo "Después de aplicar, anota el Project ID del output y actualiza"
echo "las referencias en los archivos backend.tf de las demás capas."
echo ""
echo -e "${YELLOW}IMPORTANTE: Revisa el README.md para la guía completa de despliegue${NC}"
echo ""
