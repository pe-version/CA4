# WireGuard Secret Management Strategy

## Overview

This document describes how WireGuard VPN cryptographic keys are managed in the CA4 multi-cloud deployment project. The strategy ensures that sensitive cryptographic material stays out of version control while maintaining ease of deployment.

## Problem Statement

WireGuard VPN requires cryptographic keys to establish secure tunnels between AWS and GCP clusters. These keys are sensitive and should not be committed to Git repositories, even for academic projects, as:

1. **Security Best Practice**: Keys in Git history remain forever, even if deleted later
2. **Professional Standards**: Demonstrates understanding of proper secret management
3. **Portability**: Others can deploy your code with their own keys without conflicts

## Solution Architecture

### Components

```
Repository (Safe to commit):
├── k8s/wireguard/
│   ├── wireguard-aws-template.yaml    ✅ Template with placeholders
│   ├── wireguard-gcp-template.yaml    ✅ Template with placeholders
│   ├── wireguard-aws-configured.yaml  ❌ Git-ignored (has actual keys)
│   └── wireguard-gcp-configured.yaml  ❌ Git-ignored (has actual keys)
├── scripts/
│   └── deploy-wireguard-secrets.sh    ✅ Deployment automation
└── .wireguard-keys.env                ❌ Git-ignored (stores actual keys)

Kubernetes Cluster (Runtime):
└── vpn-system namespace
    ├── Secret: wireguard-keys         🔒 Created by script
    ├── ConfigMap: wireguard-config-template
    └── Deployment: wireguard
        └── InitContainer: Merges template + secret → final config
```

### How It Works

1. **At Rest (Development)**:
   - Actual keys stored in `.wireguard-keys.env` (git-ignored)
   - Template YAML files committed to repository (safe)
   - Old configured files git-ignored (kept for backward compatibility)

2. **At Deploy Time**:
   - Script reads `.wireguard-keys.env`
   - Creates Kubernetes Secret in `vpn-system` namespace
   - Secret contains private key, peer public key, and endpoint

3. **At Runtime**:
   - Init container reads ConfigMap template and Secret
   - Generates final `wg0.conf` in emptyDir volume
   - WireGuard container mounts the generated config
   - Keys never appear in logs or Git

## Deployment Process

### Initial Setup (One-time)

1. **Ensure keys file exists**:
   ```bash
   cat .wireguard-keys.env
   ```

   Should contain:
   ```bash
   AWS_PRIVATE_KEY="..."
   AWS_PUBLIC_KEY="..."
   GCP_PRIVATE_KEY="..."
   GCP_PUBLIC_KEY="..."
   AWS_ENDPOINT="18.191.202.7:51820"
   GCP_ENDPOINT="136.115.74.42:51820"
   ```

2. **Verify .gitignore excludes keys**:
   ```bash
   git status --ignored | grep wireguard
   ```

   Should show:
   ```
   .wireguard-keys.env
   k8s/wireguard/wireguard-aws-configured.yaml
   k8s/wireguard/wireguard-gcp-configured.yaml
   ```

### Deploying to AWS Cluster

```bash
# 1. Switch to AWS context
export KUBECONFIG=~/.kube/aws-k3s-kubeconfig.yaml

# 2. Deploy secrets
./scripts/deploy-wireguard-secrets.sh aws

# 3. Apply template
kubectl apply -f k8s/wireguard/wireguard-aws-template.yaml

# 4. Verify deployment
kubectl get pods -n vpn-system
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

### Deploying to GCP Cluster

```bash
# 1. Switch to GCP context
export KUBECONFIG=~/.kube/gcp-gke-kubeconfig.yaml

# 2. Deploy secrets
./scripts/deploy-wireguard-secrets.sh gcp

# 3. Apply template
kubectl apply -f k8s/wireguard/wireguard-gcp-template.yaml

# 4. Verify deployment
kubectl get pods -n vpn-system
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

### Deploy to Both Clusters (Convenience)

```bash
# Deploy secrets to both clusters (requires switching contexts)
./scripts/deploy-wireguard-secrets.sh both
```

## Security Features

### 1. Secret Isolation
- Keys never committed to Git
- `.wireguard-keys.env` excluded via `.gitignore`
- Old configured files also git-ignored

### 2. Kubernetes Native
- Uses Kubernetes Secrets API
- Secrets encrypted at rest (if cluster configured)
- RBAC controls access to secrets

### 3. Minimal Exposure
- Init container runs once at pod start
- Generated config stored in ephemeral emptyDir volume
- Config deleted when pod terminates
- Keys not visible in logs (filtered output)

### 4. File Permissions
- Secret mounted with mode 0400 (read-only, owner only)
- Generated wg0.conf set to 600 permissions

## Verification

### Verify Secret Exists
```bash
kubectl get secret wireguard-keys -n vpn-system
```

Expected output:
```
NAME             TYPE     DATA   AGE
wireguard-keys   Opaque   3      5m
```

### Inspect Secret (Base64 Encoded)
```bash
kubectl describe secret wireguard-keys -n vpn-system
```

Expected output:
```
Data
====
aws-private-key:  44 bytes  (or gcp-private-key)
gcp-public-key:   44 bytes  (or aws-public-key)
gcp-endpoint:     21 bytes  (or aws-endpoint)
```

### Verify Init Container Logs
```bash
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

Expected output (keys filtered):
```
Generating WireGuard configuration from template and secrets...
Configuration generated successfully (keys hidden):
[Interface]
Address = 10.200.0.1/24
ListenPort = 51820
...
Setting proper permissions...
```

### Verify WireGuard Connection
```bash
kubectl exec -it -n vpn-system deployment/wireguard -- wg show
```

Expected output:
```
interface: wg0
  public key: (base64)
  private key: (hidden)
  listening port: 51820

peer: (base64)
  endpoint: IP:51820
  allowed ips: 10.200.0.0/24, ...
  latest handshake: X seconds ago
  transfer: Y GiB received, Z GiB sent
```

## Troubleshooting

### Error: Keys file not found
```
ERROR: Keys file not found at .wireguard-keys.env
```

**Solution**: Create the keys file:
```bash
cp .wireguard-keys.env.example .wireguard-keys.env
# Edit with actual keys
vim .wireguard-keys.env
```

### Error: Secret not found
```
Error from server (NotFound): secrets "wireguard-keys" not found
```

**Solution**: Deploy the secret first:
```bash
./scripts/deploy-wireguard-secrets.sh aws  # or gcp
```

### Init Container CrashLoopBackOff
```
Init:CrashLoopBackOff
```

**Debug**:
```bash
kubectl logs -n vpn-system deployment/wireguard -c config-generator
```

Common causes:
- Secret not created
- Secret has wrong key names
- Template ConfigMap missing

### WireGuard Not Connecting

**Check handshake**:
```bash
kubectl exec -n vpn-system deployment/wireguard -- wg show
```

If "latest handshake" is missing:
- Verify endpoints are correct (public IPs)
- Check firewall rules (UDP 51820)
- Verify peer public keys match

## Key Rotation

To rotate WireGuard keys (e.g., after project completion):

```bash
# 1. Generate new keys
wg genkey | tee new-privatekey | wg pubkey > new-publickey

# 2. Update .wireguard-keys.env with new keys

# 3. Update peer's public key in .wireguard-keys.env

# 4. Redeploy secrets
./scripts/deploy-wireguard-secrets.sh both

# 5. Restart WireGuard pods
kubectl rollout restart deployment/wireguard -n vpn-system
```

## Comparison: Before vs After

### Before (Keys in Git)

```yaml
# ❌ INSECURE - Keys visible in Git
data:
  wg0.conf: |
    [Interface]
    PrivateKey = OOjVnJf/HjFoNqVJqjNj1PYDW+uEvPzRIC3/L8jcA34=

    [Peer]
    PublicKey = xywq7/p3/99fLPO9Uf8g0FFZvJO3eJq5P1WV0HZoJ2I=
```

**Problems**:
- Keys committed to Git history forever
- Anyone with repo access has keys
- Can't share code publicly
- Difficult to rotate keys

### After (Keys in Secrets)

```yaml
# ✅ SECURE - Template in Git
data:
  wg0.conf.template: |
    [Interface]
    # PrivateKey injected from secret

    [Peer]
    # PublicKey injected from secret
```

```bash
# ✅ Keys stored securely
# .wireguard-keys.env (git-ignored)
AWS_PRIVATE_KEY="..."
```

**Benefits**:
- Keys never in Git
- Safe to share code
- Easy key rotation
- Professional standard

## Enterprise Alternatives

For production deployments, consider:

1. **External Secrets Operator**
   - Sync from AWS Secrets Manager / GCP Secret Manager
   - Automatic rotation support
   - Centralized secret management

2. **Sealed Secrets**
   - Encrypt secrets for Git storage
   - Bitnami Sealed Secrets controller
   - GitOps-friendly

3. **HashiCorp Vault**
   - Enterprise secret management
   - Dynamic secrets
   - Audit logging

For CA4 academic project, the Kubernetes Secret approach is appropriate and demonstrates proper secret management fundamentals.

## References

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- [12-Factor App: Config](https://12factor.net/config)
- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated**: 2025-12-03
**Maintained By**: CA4 Multi-Cloud Project
