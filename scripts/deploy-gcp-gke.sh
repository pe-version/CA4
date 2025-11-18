#!/bin/bash
# CA4 GCP GKE Deployment Script
# Deploys GKE cluster for compute tier (Producer/Processor workloads)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="metals-price-tracker"
GCP_REGION="us-central1"
GCP_ZONE="us-central1-a"
CLUSTER_NAME="ca4-gke-compute"
TERRAFORM_DIR="../terraform/gcp"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CA4 GCP GKE Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Verify Prerequisites
echo -e "${YELLOW}[1/6] Verifying prerequisites...${NC}"

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI not found${NC}"
    echo "Install: brew install --cask google-cloud-sdk"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform not found${NC}"
    echo "Install: brew install terraform"
    exit 1
fi

# Check if credentials file exists
CREDS_FILE="$HOME/.gcp/metals-price-tracker-terraform-key.json"
if [ ! -f "$CREDS_FILE" ]; then
    echo -e "${RED}Error: GCP credentials file not found${NC}"
    echo "Expected: $CREDS_FILE"
    echo "Follow GCP-SETUP-GUIDE.md to create service account key"
    exit 1
fi

echo -e "${GREEN}✓ gcloud CLI installed${NC}"
echo -e "${GREEN}✓ Terraform installed${NC}"
echo -e "${GREEN}✓ GCP credentials file found${NC}"
echo ""

# Step 2: Verify GCP APIs
echo -e "${YELLOW}[2/6] Verifying GCP APIs are enabled...${NC}"

# Authenticate with service account
gcloud auth activate-service-account --key-file="$CREDS_FILE" --project="$GCP_PROJECT_ID" > /dev/null 2>&1

# Check required APIs
REQUIRED_APIS=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --project="$GCP_PROJECT_ID" --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        echo -e "${GREEN}✓ $api enabled${NC}"
    else
        echo -e "${RED}✗ $api not enabled${NC}"
        echo "Enabling $api..."
        gcloud services enable "$api" --project="$GCP_PROJECT_ID"
    fi
done
echo ""

# Step 3: Initialize Terraform
echo -e "${YELLOW}[3/6] Initializing Terraform...${NC}"
cd "$TERRAFORM_DIR"

terraform init
echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Step 4: Terraform Plan
echo -e "${YELLOW}[4/6] Generating Terraform plan...${NC}"
terraform plan -out=tfplan

echo ""
echo -e "${BLUE}Review the plan above. Expected resources:${NC}"
echo "  • VPC network"
echo "  • Subnet with secondary IP ranges (pods/services)"
echo "  • 4 firewall rules (internal, WireGuard, SSH)"
echo "  • GKE cluster (ca4-gke-compute)"
echo "  • GKE node pool (2 x e2-medium)"
echo "  • Static IP (VPN gateway)"
echo ""

read -p "Apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi
echo ""

# Step 5: Apply Terraform
echo -e "${YELLOW}[5/6] Deploying GCP infrastructure...${NC}"
echo -e "${BLUE}This will take 5-8 minutes...${NC}"

terraform apply tfplan

echo -e "${GREEN}✓ GCP infrastructure deployed${NC}"
echo ""

# Step 6: Configure kubectl
echo -e "${YELLOW}[6/6] Configuring kubectl for GKE cluster...${NC}"

# Get cluster credentials
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --zone="$GCP_ZONE" \
    --project="$GCP_PROJECT_ID"

# Verify connection
echo ""
echo -e "${BLUE}GKE Cluster Nodes:${NC}"
kubectl get nodes

echo ""
echo -e "${BLUE}GKE Cluster Info:${NC}"
kubectl cluster-info

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GCP GKE Deployment Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Display outputs
echo -e "${BLUE}Terraform Outputs:${NC}"
terraform output deployment_summary

echo ""
echo -e "${BLUE}VPN Gateway IP:${NC}"
terraform output vpn_gateway_ip

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. ✓ GKE cluster deployed (2 nodes)"
echo "2. ⏭️  Set up WireGuard VPN (connect AWS ↔ GCP)"
echo "3. ⏭️  Deploy Producer/Processor to GKE"
echo "4. ⏭️  Configure cross-cloud observability"
echo "5. ⏭️  Test VPN connectivity"
echo ""

echo -e "${YELLOW}Useful Commands:${NC}"
echo "  kubectl config current-context    # Show current cluster"
echo "  kubectl get nodes                 # List GKE nodes"
echo "  kubectl get namespaces            # List namespaces"
echo "  terraform output                  # Show all outputs"
echo ""

echo -e "${GREEN}Cost: \$0 (using GCP free credits)${NC}"
echo ""
