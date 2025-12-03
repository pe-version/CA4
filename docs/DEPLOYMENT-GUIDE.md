# CA4 Multi-Cloud Deployment Guide

**Status**: ✅ **Complete and Operational**
**Last Updated**: December 3, 2025
**Architecture**: AWS K3s (Data Tier) + GCP GKE (Compute Tier) + WireGuard VPN

---

## Overview

This guide covers the complete deployment of the CA4 multi-cloud metals price tracking application across AWS and GCP with encrypted VPN connectivity.

**Final Architecture**:
```
┌─────────────────────────────────────────────────────────────────┐
│  GCP (us-central1)          WireGuard VPN        AWS (us-east-2) │
│  Compute Tier            (Encrypted Tunnel)       Data Tier      │
├─────────────────────────  ───────────── ──────────────────────────┤
│                                                                   │
│  Producer (1/1) ──────┐                    ┌─── Kafka (1/1)      │
│  Processor (1/1) ─────┼────── 10.200.0.0/24├─── MongoDB (1/1)    │
│  WireGuard (1/1) ─────┘     VPN Tunnel     └─── Zookeeper (1/1)  │
│                                                  WireGuard (1/1)  │
│  2x e2-standard-2                                1x t3.medium     │
└─────────────────────────────────────────────────────────────────┘
```

**Data Flow**:
1. Producer (GCP) → Kafka (AWS) via VPN
2. Processor (GCP) → Kafka (AWS) → MongoDB (AWS) via VPN
3. All traffic encrypted through WireGuard tunnel

---

## Prerequisites

### Required Tools
- **Terraform** >= 1.5
- **kubectl** >= 1.28
- **gcloud CLI** (for GCP)
- **AWS CLI** (for AWS)
- **SSH client** with key: `~/.ssh/ca0-keys.pem`

### Required Credentials
- AWS account with EC2 access
- GCP account with $300 free credits
- Service account key: `~/.gcp/metals-price-tracker-terraform-key.json`

---

## Part 1: AWS Infrastructure (Data Tier)

### 1.1 Deploy AWS K3s Cluster

```bash
cd terraform

# Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set your IP address

# Deploy infrastructure
terraform init
terraform plan
terraform apply

# Expected resources:
# - 1x t3.medium EC2 instance (master node)
# - VPC with 10.0.0.0/16 CIDR
# - Security group with SSH, K3s API, WireGuard access
```

### 1.2 Deploy Data Services to AWS

```bash
# Get AWS master IP from Terraform output
AWS_MASTER_IP=$(terraform output -raw master_public_ip)

# Copy manifests to AWS
scp -i ~/.ssh/ca0-keys.pem -r k8s/aws ubuntu@${AWS_MASTER_IP}:/tmp/

# Deploy all services
ssh -i ~/.ssh/ca0-keys.pem ubuntu@${AWS_MASTER_IP} \
  "sudo k3s kubectl apply -f /tmp/aws/"

# Verify deployment
ssh -i ~/.ssh/ca0-keys.pem ubuntu@${AWS_MASTER_IP} \
  "sudo k3s kubectl get pods -n ca3-app"

# Expected output:
# NAME          READY   STATUS    RESTARTS   AGE
# kafka-0       1/1     Running   0          2m
# mongodb-0     1/1     Running   0          2m
# zookeeper-0   1/1     Running   0          2m
```

---

## Part 2: GCP Infrastructure (Compute Tier)

### 2.1 Deploy GCP GKE Cluster

```bash
cd terraform/gcp

# Configure GCP credentials
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set project_id and credentials_file

# Deploy infrastructure
terraform init
terraform plan
terraform apply

# Expected resources:
# - GKE cluster with 2x e2-standard-2 nodes
# - VPC with pod/service secondary ranges
# - Static IP for VPN gateway
# - Firewall rules for VPN
```

### 2.2 Configure kubectl for GKE

```bash
# Source GCP environment
source scripts/setup-gcloud-env.sh

# Get GKE credentials
gcloud container clusters get-credentials ca4-gke-compute \
  --zone=us-central1-a \
  --project=metals-price-tracker

# Verify cluster access
kubectl get nodes

# Expected output:
# NAME                                          STATUS   ROLES    AGE
# gke-ca4-gke-compute-default-pool-xxxxx-xxxx   Ready    <none>   5m
# gke-ca4-gke-compute-default-pool-xxxxx-xxxx   Ready    <none>   5m
```

---

## Part 3: WireGuard VPN Setup

### 3.1 Deploy WireGuard Secrets

The WireGuard keys are managed via Kubernetes secrets (not in Git).

```bash
# Deploy secrets to AWS
export KUBECONFIG=~/.kube/aws-k3s-kubeconfig.yaml
./scripts/deploy-wireguard-secrets.sh aws

# Deploy secrets to GCP
export KUBECONFIG=~/.kube/gcp-gke-kubeconfig.yaml
./scripts/deploy-wireguard-secrets.sh gcp
```

### 3.2 Deploy WireGuard Pods

```bash
# Deploy to AWS
export KUBECONFIG=~/.kube/aws-k3s-kubeconfig.yaml
kubectl apply -f k8s/wireguard/wireguard-aws-template.yaml

# Deploy to GCP
export KUBECONFIG=~/.kube/gcp-gke-kubeconfig.yaml
kubectl apply -f k8s/wireguard/wireguard-gcp-template.yaml

# Verify both pods are running
kubectl get pods -n vpn-system
```

### 3.3 Verify VPN Tunnel

```bash
# Test GCP → AWS connectivity
kubectl exec -n vpn-system deployment/wireguard -- ping -c 4 10.200.0.1

# Expected: 0% packet loss, ~20ms latency

# Check WireGuard status
kubectl exec -n vpn-system deployment/wireguard -- wg show

# Expected: "latest handshake: X seconds ago"
```

---

## Part 4: Deploy Applications to GCP

### 4.1 Deploy Producer and Processor

```bash
# Set GCP context
export KUBECONFIG=~/.kube/gcp-gke-kubeconfig.yaml

# Deploy all GCP manifests
kubectl apply -f k8s/gcp/

# Verify deployments
kubectl get pods -n ca3-app

# Expected output:
# NAME                         READY   STATUS    RESTARTS   AGE
# producer-xxxxx-xxxxx         1/1     Running   0          2m
# processor-xxxxx-xxxxx        1/1     Running   0          2m
```

### 4.2 Verify End-to-End Data Flow

```bash
# Check Producer logs (should show sending messages)
kubectl logs -n ca3-app -l app=producer --tail=20

# Expected: "Sent: aluminum @ $2.16 (msg #90)"

# Check Processor logs (should show processing messages)
kubectl logs -n ca3-app -l app=processor --tail=20

# Expected: "Processed: aluminum @ $2.16"

# Verify MongoDB has data (from AWS)
ssh -i ~/.ssh/ca0-keys.pem ubuntu@${AWS_MASTER_IP} \
  "sudo k3s kubectl exec -n ca3-app mongodb-0 -- \
    mongosh metals_db --eval 'db.prices.countDocuments()'"

# Expected: positive count
```

---

## Part 5: Verification & Testing

### 5.1 Health Checks

```bash
# AWS Services
kubectl get pods -n ca3-app --context aws
kubectl get svc -n ca3-app --context aws

# GCP Services
kubectl get pods -n ca3-app --context gcp
kubectl get svc -n ca3-app --context gcp

# VPN Status
kubectl exec -n vpn-system deployment/wireguard --context gcp -- wg show
```

### 5.2 Network Connectivity Tests

```bash
# GCP WireGuard pod can reach AWS node
kubectl exec -n vpn-system deployment/wireguard --context gcp -- \
  ping -c 4 10.0.1.154

# GCP Producer can reach Kafka via WireGuard service
kubectl exec -n ca3-app deployment/producer --context gcp -- \
  nc -zv 10.101.94.73 9092
```

---

## Troubleshooting

### Issue: Pods Not Starting

**Check pod status**:
```bash
kubectl describe pod <pod-name> -n ca3-app
kubectl logs <pod-name> -n ca3-app
```

**Common causes**:
- Image pull errors → Check image names
- Resource constraints → Check node resources
- Mount failures → Check secrets/configmaps exist

### Issue: VPN Not Connecting

**Check WireGuard logs**:
```bash
kubectl logs -n vpn-system deployment/wireguard
```

**Common causes**:
- Firewall blocking UDP 51820 → Check security groups/firewall rules
- Wrong peer public key → Verify keys match
- Endpoint IP incorrect → Check static IPs in manifests

### Issue: Producer/Processor Can't Reach Kafka

**Check connectivity from pod**:
```bash
kubectl exec -n ca3-app deployment/producer -- \
  nc -zv 10.101.94.73 9092
```

**Common causes**:
- WireGuard service not created → Check `kubectl get svc -n vpn-system`
- hostAliases not configured → Check pod YAML
- Kafka advertised listeners incorrect → Check Kafka config

---

## Architecture Details

### Network Configuration

| Component | CIDR/IP | Purpose |
|-----------|---------|---------|
| AWS VPC | 10.0.0.0/16 | K3s cluster network |
| AWS VPN Tunnel | 10.200.0.1/24 | WireGuard endpoint |
| GCP VPC | 10.1.0.0/24 | GKE nodes |
| GCP Pod CIDR | 10.100.0.0/16 | GKE pods |
| GCP Service CIDR | 10.101.0.0/16 | GKE services |
| GCP VPN Tunnel | 10.200.0.2/24 | WireGuard endpoint |

### Service Endpoints

**AWS (Internal)**:
- Kafka: `kafka-0.kafka.ca3-app.svc.cluster.local:9092`
- MongoDB: `mongodb-0.mongodb.ca3-app.svc.cluster.local:27017`
- Zookeeper: `zookeeper-0.zookeeper.ca3-app.svc.cluster.local:2181`

**AWS (NodePort for VPN Access)**:
- Kafka: `10.0.1.154:30092`
- MongoDB: `10.0.1.154:30017`

**GCP (Via WireGuard Service)**:
- Producer → Kafka: `10.101.94.73:9092` (resolves to AWS via hostAliases)
- Processor → Kafka: `10.101.94.73:9092`
- Processor → MongoDB: `10.101.94.73:27017`

---

## Cost Estimate

| Resource | Quantity | Cost/Month |
|----------|----------|------------|
| AWS t3.medium | 1 | ~$30 |
| GCP e2-standard-2 | 2 | $0 (free credits) |
| **Total** | | **~$30/month** |

*Note: GCP free during 90-day $300 credit period*

---

## Security Notes

1. **Secrets Management**: WireGuard keys stored in Kubernetes secrets, not in Git
2. **Network Isolation**: VPN tunnel encrypted with ChaCha20-Poly1305
3. **Firewall Rules**: SSH restricted to specific IPs, VPN open for cross-cloud
4. **Kubernetes RBAC**: Default service account restrictions apply

---

## Additional Resources

- [WireGuard Secret Management](WIREGUARD-SECRET-MANAGEMENT.md) - Key management strategy
- [SSH Access Strategy](SSH-ACCESS-STRATEGY.md) - SSH security considerations
- [WireGuard Deployment Quickstart](../WIREGUARD-DEPLOYMENT-QUICKSTART.md) - Quick reference

---

**Deployment Complete!** Your multi-cloud application should now be running with:
- ✅ Encrypted VPN tunnel between AWS and GCP
- ✅ Producer sending metals prices from GCP to AWS Kafka
- ✅ Processor consuming from Kafka and writing to MongoDB
- ✅ All communication secured via WireGuard
