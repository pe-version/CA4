# WireGuard VPN Setup Status

**Date**: November 30, 2025
**Status**: 🟡 **In Progress** - GCP Complete, AWS Pending SSH Connection

---

## ✅ Completed Steps

### 1. WireGuard Key Generation (COMPLETE)
- ✅ Generated AWS VPN gateway keys using native `wg` tools
- ✅ Generated GCP VPN gateway keys using native `wg` tools
- ✅ Keys stored securely in `k8s/wireguard/*.key` (gitignored)
- ✅ Permissions set to 600 (read-only for owner)

**Keys**:
```
AWS Private: OOjVnJf/HjFoNqVJqjNj1PYDW+uEvPzRIC3/L8jcA34=
AWS Public:  x8X0zPj5QkMjUM4+GA2Nhf2taUgnTfMGZJV1d/aqARI=

GCP Private: sPGCmpL8M0EccvJHxOB+gnOO0scn3KmnTdasyo8D5E4=
GCP Public:  xywq7/p3/99fLPO9Uf8g0FFZvJO3eJq5P1WV0HZoJ2I=
```

---

### 2. WireGuard Manifest Creation (COMPLETE)
- ✅ Created `k8s/wireguard/wireguard-aws.yaml` (template)
- ✅ Created `k8s/wireguard/wireguard-gcp.yaml` (template)
- ✅ Created `scripts/configure-wireguard.sh` (key injection script)
- ✅ Generated `k8s/wireguard/wireguard-aws-configured.yaml` (with real keys)
- ✅ Generated `k8s/wireguard/wireguard-gcp-configured.yaml` (with real keys)

**Configuration**:
- AWS VPN: `10.200.0.1/24` (tunnel IP)
- GCP VPN: `10.200.0.2/24` (tunnel IP)
- AWS Endpoint: `3.145.176.214:51820`
- GCP Endpoint: `136.115.74.42:51820`

---

### 3. GCP WireGuard Deployment (COMPLETE)
- ✅ Deployed WireGuard to GCP cluster
- ✅ Created `vpn-system` namespace
- ✅ WireGuard pod: **Running**
- ✅ LoadBalancer service: **External IP assigned (136.115.74.42)**
- ✅ Listening on UDP port 51820

**Verification**:
```bash
kubectl config use-context gke_metals-price-tracker_us-central1-a_ca4-gke-compute
kubectl get pods -n vpn-system
# NAME                         READY   STATUS    RESTARTS   AGE
# wireguard-74547f9f8c-rnhf8   1/1     Running   0          52s

kubectl get svc -n vpn-system
# NAME            TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
# wireguard-vpn   LoadBalancer   10.101.167.145   136.115.74.42   51820:31253/UDP
```

---

### 4. AWS Security Group Update (COMPLETE)
- ✅ Updated `terraform.tfvars` with new IP: `181.214.150.182/32`
- ✅ Applied Terraform changes to AWS security group
- ✅ Now allows SSH (port 22) from current IP
- ✅ Now allows K3s API (port 6443) from current IP

**Terraform Command Used**:
```bash
terraform apply -target=aws_security_group.k3s_sg -auto-approve
```

---

## ⏳ Pending Steps

### 5. AWS WireGuard Deployment (PENDING)
**Status**: Waiting for SSH connection to AWS master node

**Next Steps**:
1. **Test SSH Connection** (currently connecting):
   ```bash
   ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214
   ```

2. **Deploy WireGuard to AWS K3s**:
   ```bash
   # Copy manifest to AWS master
   scp -i ~/.ssh/ca0-keys.pem k8s/wireguard/wireguard-aws-configured.yaml \
       ubuntu@3.145.176.214:/tmp/

   # Apply via SSH
   ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214 \
       "sudo k3s kubectl apply -f /tmp/wireguard-aws-configured.yaml"

   # Verify deployment
   ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214 \
       "sudo k3s kubectl get pods -n vpn-system"
   ```

**Estimated Time**: 5-10 minutes

---

### 6. Add WireGuard to AWS Security Group (PENDING)

The AWS security group currently does NOT allow UDP port 51820 (WireGuard). You need to add this rule.

**Option A: Via Terraform** (Recommended):

Edit `terraform/main.tf` and add this ingress rule to `aws_security_group.k3s_sg`:

```hcl
# WireGuard VPN from GCP
ingress {
  from_port   = 51820
  to_port     = 51820
  protocol    = "udp"
  cidr_blocks = ["136.115.74.42/32", "0.0.0.0/0"]  # GCP VPN gateway IP
  description = "WireGuard VPN from GCP"
}
```

Then apply:
```bash
terraform apply -target=aws_security_group.k3s_sg
```

**Option B: Via AWS Console** (Quick):
1. Go to: https://console.aws.amazon.com/ec2/v2/home?region=us-east-2#SecurityGroups:
2. Find security group: `CA3-K3s-3Node-sg`
3. Add inbound rule:
   - Type: Custom UDP
   - Port: 51820
   - Source: `0.0.0.0/0` (or `136.115.74.42/32` for GCP only)
   - Description: WireGuard VPN from GCP

**Estimated Time**: 5 minutes

---

### 7. Test VPN Connectivity (PENDING)

Once both WireGuard pods are running:

**From GCP to AWS**:
```bash
# Get GCP WireGuard pod name
kubectl config use-context gke_metals-price-tracker_us-central1-a_ca4-gke-compute
kubectl get pods -n vpn-system

# Exec into GCP WireGuard pod
kubectl exec -it -n vpn-system wireguard-XXXXX -- /bin/bash

# Test connectivity
ping -c 4 10.200.0.1    # AWS VPN tunnel IP
ping -c 4 10.0.1.120    # AWS master private IP
```

**From AWS to GCP**:
```bash
# SSH to AWS master
ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214

# Get AWS WireGuard pod
sudo k3s kubectl get pods -n vpn-system

# Exec into AWS WireGuard pod
sudo k3s kubectl exec -it -n vpn-system wireguard-XXXXX -- /bin/bash

# Test connectivity
ping -c 4 10.200.0.2    # GCP VPN tunnel IP
ping -c 4 10.1.0.0      # GCP node IP
```

**Expected Result**: Successful ping responses mean VPN tunnel is working!

**Estimated Time**: 5-10 minutes

---

### 8. Verify Encrypted Tunnel (PENDING)

**Check WireGuard Status**:
```bash
# On AWS WireGuard pod
wg show

# Should show:
# interface: wg0
#   public key: x8X0zPj5QkMjUM4+GA2Nhf2taUgnTfMGZJV1d/aqARI=
#   private key: (hidden)
#   listening port: 51820
#
# peer: xywq7/p3/99fLPO9Uf8g0FFZvJO3eJq5P1WV0HZoJ2I=  # GCP public key
#   endpoint: 136.115.74.42:51820
#   allowed ips: 10.200.0.2/32, 10.1.0.0/24, ...
#   latest handshake: X seconds ago
#   transfer: X B received, Y B sent
```

**Estimated Time**: 5 minutes

---

## 📊 Overall Progress

| Phase | Status | Time Spent | Time Remaining |
|-------|--------|------------|----------------|
| Key Generation | ✅ Complete | 10 min | - |
| Manifest Creation | ✅ Complete | 15 min | - |
| GCP Deployment | ✅ Complete | 5 min | - |
| AWS Security Update | ✅ Complete | 10 min | - |
| **AWS Deployment** | ⏳ **Pending** | - | **10 min** |
| **VPN Testing** | ⏳ **Pending** | - | **10 min** |
| **Verification** | ⏳ **Pending** | - | **5 min** |
| **Total** | **57% Complete** | **40 min** | **25 min** |

---

## 🎯 Quick Resume Commands

When you're ready to continue:

### 1. Test AWS SSH Access
```bash
ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214
```

### 2. Deploy WireGuard to AWS
```bash
cd /Users/jr.ikamp/Downloads/CA4

# Copy manifest
scp -i ~/.ssh/ca0-keys.pem k8s/wireguard/wireguard-aws-configured.yaml \
    ubuntu@3.145.176.214:/tmp/

# Deploy
ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214 \
    "sudo k3s kubectl apply -f /tmp/wireguard-aws-configured.yaml"
```

### 3. Add WireGuard Port to AWS Security Group
```bash
# Add to terraform/main.tf (line ~110)
# Then:
terraform apply -target=aws_security_group.k3s_sg
```

### 4. Test VPN
```bash
# GCP side
source scripts/setup-gcloud-env.sh
kubectl config use-context gke_metals-price-tracker_us-central1-a_ca4-gke-compute
kubectl exec -it -n vpn-system $(kubectl get pod -n vpn-system -o name) -- ping -c 4 10.200.0.1

# AWS side
ssh -i ~/.ssh/ca0-keys.pem ubuntu@3.145.176.214 \
    "sudo k3s kubectl exec -n vpn-system \$(sudo k3s kubectl get pod -n vpn-system -o name) -- ping -c 4 10.200.0.2"
```

---

## 🔐 Important Files

**Created Files** (gitignored):
- `k8s/wireguard/aws-private.key`
- `k8s/wireguard/aws-public.key`
- `k8s/wireguard/gcp-private.key`
- `k8s/wireguard/gcp-public.key`
- `k8s/wireguard/wireguard-aws-configured.yaml`
- `k8s/wireguard/wireguard-gcp-configured.yaml`

**⚠️ NEVER commit these files to Git!** They contain private keys.

---

## 📚 Network Configuration Reference

### IP Address Allocation

| Component | IP/CIDR | Purpose |
|-----------|---------|---------|
| **AWS VPC** | 10.0.0.0/16 | AWS K3s cluster network |
| **AWS Master** | 10.0.1.120 | K3s control plane |
| **AWS VPN Tunnel** | 10.200.0.1/24 | WireGuard tunnel endpoint |
| **AWS Public IP** | 3.145.176.214 | Internet-facing endpoint |
| **GCP VPC** | 10.1.0.0/24 | GCP GKE cluster network |
| **GCP Pods** | 10.100.0.0/16 | GKE pod IP range |
| **GCP Services** | 10.101.0.0/16 | GKE service IP range |
| **GCP VPN Tunnel** | 10.200.0.2/24 | WireGuard tunnel endpoint |
| **GCP Public IP** | 136.115.74.42 | LoadBalancer VPN endpoint |

### Firewall Rules

**AWS Security Group** (`sg-03e6e8da69e4670af`):
- ✅ SSH (22/tcp) from 181.214.150.182/32
- ✅ K3s API (6443/tcp) from 181.214.150.182/32
- ⏳ WireGuard (51820/udp) - **NEEDS TO BE ADDED**
- ✅ Internal traffic (all ports) within 10.0.0.0/16

**GCP Firewall** (`ca4-gcp-vpc-allow-wireguard`):
- ✅ WireGuard (51820/udp) from 0.0.0.0/0

---

## 🎓 For Your Assignment Documentation

**What You've Accomplished**:
1. ✅ Generated cryptographic keys for secure VPN
2. ✅ Created Kubernetes manifests for both cloud providers
3. ✅ Successfully deployed WireGuard to GCP (GKE)
4. ✅ Configured cross-cloud networking (IP allocation)
5. ✅ Updated AWS security policies for new IP access

**What This Demonstrates**:
- Multi-cloud infrastructure management
- Secure VPN configuration (WireGuard)
- Kubernetes deployment across providers (K3s + GKE)
- Infrastructure as Code (Terraform)
- Network security (security groups, firewall rules)

**Remaining Work** (~25 minutes):
- Deploy WireGuard to AWS K3s
- Configure AWS firewall for VPN traffic
- Test and verify encrypted tunnel

---

**Last Updated**: November 30, 2025
**Total Time Invested**: 40 minutes
**Estimated Time to Complete**: 25 minutes
**Overall Completion**: 57%
