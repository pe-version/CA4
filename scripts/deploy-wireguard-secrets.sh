#!/bin/bash

# deploy-wireguard-secrets.sh
# Creates Kubernetes secrets for WireGuard VPN configuration
# This keeps cryptographic keys out of Git while maintaining proper secret management
#
# Usage:
#   ./scripts/deploy-wireguard-secrets.sh aws    # Deploy to AWS K3s cluster
#   ./scripts/deploy-wireguard-secrets.sh gcp    # Deploy to GCP GKE cluster
#   ./scripts/deploy-wireguard-secrets.sh both   # Deploy to both clusters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYS_FILE="$PROJECT_ROOT/.wireguard-keys.env"

# Check if keys file exists
if [ ! -f "$KEYS_FILE" ]; then
    echo -e "${RED}ERROR: Keys file not found at $KEYS_FILE${NC}"
    echo ""
    echo "Please create the .wireguard-keys.env file with your WireGuard keys."
    echo "See .wireguard-keys.env.example for the required format."
    exit 1
fi

# Source the keys
echo -e "${YELLOW}Loading WireGuard keys from $KEYS_FILE...${NC}"
source "$KEYS_FILE"

# Validate required variables
required_vars=("AWS_PRIVATE_KEY" "AWS_PUBLIC_KEY" "AWS_ENDPOINT" "GCP_PRIVATE_KEY" "GCP_PUBLIC_KEY" "GCP_ENDPOINT")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}ERROR: $var is not set in $KEYS_FILE${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ All required keys found${NC}"

# Function to deploy secrets to AWS
deploy_aws() {
    echo ""
    echo -e "${YELLOW}Deploying WireGuard secrets to AWS K3s cluster...${NC}"

    # Check if namespace exists, create if not
    if ! kubectl get namespace vpn-system &> /dev/null; then
        echo "Creating vpn-system namespace..."
        kubectl create namespace vpn-system
    fi

    # Delete existing secret if it exists
    if kubectl get secret wireguard-keys -n vpn-system &> /dev/null; then
        echo "Deleting existing secret..."
        kubectl delete secret wireguard-keys -n vpn-system
    fi

    # Create the secret
    echo "Creating wireguard-keys secret..."
    kubectl create secret generic wireguard-keys \
        --from-literal=aws-private-key="$AWS_PRIVATE_KEY" \
        --from-literal=gcp-public-key="$GCP_PUBLIC_KEY" \
        --from-literal=gcp-endpoint="$GCP_ENDPOINT" \
        -n vpn-system

    echo -e "${GREEN}✓ AWS WireGuard secrets deployed successfully${NC}"
    echo ""
    echo "Next steps:"
    echo "  kubectl apply -f k8s/wireguard/wireguard-aws-template.yaml"
}

# Function to deploy secrets to GCP
deploy_gcp() {
    echo ""
    echo -e "${YELLOW}Deploying WireGuard secrets to GCP GKE cluster...${NC}"

    # Check if namespace exists, create if not
    if ! kubectl get namespace vpn-system &> /dev/null; then
        echo "Creating vpn-system namespace..."
        kubectl create namespace vpn-system
    fi

    # Delete existing secret if it exists
    if kubectl get secret wireguard-keys -n vpn-system &> /dev/null; then
        echo "Deleting existing secret..."
        kubectl delete secret wireguard-keys -n vpn-system
    fi

    # Create the secret
    echo "Creating wireguard-keys secret..."
    kubectl create secret generic wireguard-keys \
        --from-literal=gcp-private-key="$GCP_PRIVATE_KEY" \
        --from-literal=aws-public-key="$AWS_PUBLIC_KEY" \
        --from-literal=aws-endpoint="$AWS_ENDPOINT" \
        -n vpn-system

    echo -e "${GREEN}✓ GCP WireGuard secrets deployed successfully${NC}"
    echo ""
    echo "Next steps:"
    echo "  kubectl apply -f k8s/wireguard/wireguard-gcp-template.yaml"
}

# Parse command line argument
case "${1:-}" in
    aws)
        deploy_aws
        ;;
    gcp)
        deploy_gcp
        ;;
    both)
        deploy_aws
        echo ""
        echo "----------------------------------------"
        deploy_gcp
        ;;
    *)
        echo "Usage: $0 {aws|gcp|both}"
        echo ""
        echo "Examples:"
        echo "  $0 aws     # Deploy secrets to AWS K3s cluster"
        echo "  $0 gcp     # Deploy secrets to GCP GKE cluster"
        echo "  $0 both    # Deploy secrets to both clusters"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Deployment complete${NC}"
echo ""
echo "Security reminder: The .wireguard-keys.env file contains sensitive keys."
echo "Ensure it is excluded from Git (check .gitignore) and has proper file permissions."
echo ""
echo "Verify with:"
echo "  kubectl get secrets -n vpn-system"
echo "  kubectl describe secret wireguard-keys -n vpn-system"
