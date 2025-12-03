#!/bin/bash
# Configure WireGuard manifests with generated keys
# This script replaces placeholders with actual WireGuard keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WIREGUARD_DIR="$PROJECT_ROOT/k8s/wireguard"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================"
echo "  WireGuard VPN Configuration Script"
echo "========================================"
echo ""

# Check if key files exist
if [ ! -f "$WIREGUARD_DIR/aws-private.key" ] || [ ! -f "$WIREGUARD_DIR/aws-public.key" ] || \
   [ ! -f "$WIREGUARD_DIR/gcp-private.key" ] || [ ! -f "$WIREGUARD_DIR/gcp-public.key" ]; then
    echo -e "${RED}✗ Error: WireGuard key files not found${NC}"
    echo "Expected files in: $WIREGUARD_DIR/"
    echo "  - aws-private.key"
    echo "  - aws-public.key"
    echo "  - gcp-private.key"
    echo "  - gcp-public.key"
    exit 1
fi

# Read keys
AWS_PRIVATE=$(cat "$WIREGUARD_DIR/aws-private.key")
AWS_PUBLIC=$(cat "$WIREGUARD_DIR/aws-public.key")
GCP_PRIVATE=$(cat "$WIREGUARD_DIR/gcp-private.key")
GCP_PUBLIC=$(cat "$WIREGUARD_DIR/gcp-public.key")

echo -e "${GREEN}✓${NC} Found all WireGuard keys"
echo ""

# Display keys (for verification)
echo "AWS VPN Gateway:"
echo "  Private: ${AWS_PRIVATE:0:20}... (truncated)"
echo "  Public:  $AWS_PUBLIC"
echo ""
echo "GCP VPN Gateway:"
echo "  Private: ${GCP_PRIVATE:0:20}... (truncated)"
echo "  Public:  $GCP_PUBLIC"
echo ""

# Configure AWS manifest
echo "Configuring AWS manifest..."
sed "s|AWS_PRIVATE_KEY_PLACEHOLDER|$AWS_PRIVATE|g" "$WIREGUARD_DIR/wireguard-aws.yaml" | \
sed "s|GCP_PUBLIC_KEY_PLACEHOLDER|$GCP_PUBLIC|g" > "$WIREGUARD_DIR/wireguard-aws-configured.yaml"

echo -e "${GREEN}✓${NC} Created: wireguard-aws-configured.yaml"

# Configure GCP manifest
echo "Configuring GCP manifest..."
sed "s|GCP_PRIVATE_KEY_PLACEHOLDER|$GCP_PRIVATE|g" "$WIREGUARD_DIR/wireguard-gcp.yaml" | \
sed "s|AWS_PUBLIC_KEY_PLACEHOLDER|$AWS_PUBLIC|g" > "$WIREGUARD_DIR/wireguard-gcp-configured.yaml"

echo -e "${GREEN}✓${NC} Created: wireguard-gcp-configured.yaml"

echo ""
echo "========================================"
echo "  Configuration Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Deploy to AWS cluster:"
echo "   kubectl config use-context kind-ca3-ca3"
echo "   kubectl apply -f k8s/wireguard/wireguard-aws-configured.yaml"
echo ""
echo "2. Deploy to GCP cluster:"
echo "   kubectl config use-context gke_metals-price-tracker_us-central1-a_ca4-gke-compute"
echo "   kubectl apply -f k8s/wireguard/wireguard-gcp-configured.yaml"
echo ""
echo "3. Verify VPN connectivity:"
echo "   ./scripts/test-vpn-connectivity.sh"
echo ""
echo -e "${YELLOW}⚠  Important:${NC} The *-configured.yaml files contain private keys!"
echo "   They are gitignored and should never be committed."
echo ""
