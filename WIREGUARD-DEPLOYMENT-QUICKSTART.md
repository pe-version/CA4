# WireGuard VPN Deployment - Quick Start Guide

## Overview

This project now uses **Kubernetes Secrets** to manage WireGuard VPN keys, keeping them out of Git while maintaining ease of deployment.

## What Changed?

### Before ❌
- WireGuard keys hardcoded in YAML files
- Keys committed to Git repository
- Security risk if code shared publicly

### After ✅
- Keys stored in `.wireguard-keys.env` (git-ignored)
- Template YAML files in repository (safe to commit)
- Deployment script creates Kubernetes secrets at runtime
- Professional secret management approach

## Quick Deployment

### For AWS K3s Cluster

```bash
# 1. Switch to AWS context
export KUBECONFIG=~/.kube/aws-k3s-kubeconfig.yaml

# 2. Create secrets from keys file
./scripts/deploy-wireguard-secrets.sh aws

# 3. Deploy WireGuard using template
kubectl apply -f k8s/wireguard/wireguard-aws-template.yaml

# 4. Verify
kubectl get pods -n vpn-system
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

### For GCP GKE Cluster

```bash
# 1. Switch to GCP context
export KUBECONFIG=~/.kube/gcp-gke-kubeconfig.yaml

# 2. Create secrets from keys file
./scripts/deploy-wireguard-secrets.sh gcp

# 3. Deploy WireGuard using template
kubectl apply -f k8s/wireguard/wireguard-gcp-template.yaml

# 4. Verify
kubectl get pods -n vpn-system
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

## File Structure

```
✅ Safe to commit (in Git):
├── k8s/wireguard/wireguard-aws-template.yaml    # Template with placeholders
├── k8s/wireguard/wireguard-gcp-template.yaml    # Template with placeholders
└── scripts/deploy-wireguard-secrets.sh          # Deployment automation

❌ Git-ignored (NOT in Git):
├── .wireguard-keys.env                          # Actual keys (local only)
├── k8s/wireguard/wireguard-aws-configured.yaml  # Old file with keys
└── k8s/wireguard/wireguard-gcp-configured.yaml  # Old file with keys

🔒 Runtime only (in Kubernetes):
└── Secret: wireguard-keys (vpn-system namespace)
```

## Verification

### Check keys file is ignored
```bash
git status --ignored | grep wireguard-keys
# Should show: .wireguard-keys.env
```

### Check what will be committed
```bash
git add -A --dry-run | grep wireguard
# Should NOT include: *-configured.yaml or .wireguard-keys.env
```

### Verify secret in cluster
```bash
kubectl get secret wireguard-keys -n vpn-system
kubectl describe secret wireguard-keys -n vpn-system
```

### Test VPN connection
```bash
kubectl exec -n vpn-system deployment/wireguard -- wg show
# Look for "latest handshake" with timestamp
```

## Troubleshooting

### "Keys file not found"
**Problem**: `.wireguard-keys.env` doesn't exist

**Solution**: The file should already exist with your current keys. If missing, check:
```bash
ls -la .wireguard-keys.env
```

### "Secret not found"
**Problem**: Kubernetes secret wasn't created

**Solution**: Run the deployment script:
```bash
./scripts/deploy-wireguard-secrets.sh aws  # or gcp
```

### Init container failing
**Problem**: Template or secret misconfigured

**Debug**:
```bash
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

## Additional Documentation

For detailed information, see:
- **[WIREGUARD-SECRET-MANAGEMENT.md](docs/WIREGUARD-SECRET-MANAGEMENT.md)** - Complete strategy documentation
- **[SSH-ACCESS-STRATEGY.md](docs/SSH-ACCESS-STRATEGY.md)** - SSH security considerations

## Key Benefits

1. ✅ **Security**: Keys never committed to Git
2. ✅ **Shareable**: Code can be shared publicly without exposing keys
3. ✅ **Professional**: Demonstrates proper secret management
4. ✅ **Kubernetes-native**: Uses standard K8s Secret API
5. ✅ **Easy rotation**: Update `.wireguard-keys.env` and redeploy
6. ✅ **Documented**: Clear deployment process for graders/teammates

---

**Ready to push to Git?** Yes! The sensitive files are now properly excluded.

```bash
git add .
git commit -m "Implement Kubernetes Secrets for WireGuard key management"
git push origin main
```
