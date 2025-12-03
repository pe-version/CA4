# CA4: Multi-Cloud Deployment with Encrypted VPN

**Student**: Philip Eykamp
**Course**: CS 5287 - DevOps Engineering
**Assignment**: CA4 - Multi-Hybrid Cloud Operations
**Status**: ✅ **Complete and Operational**
**Last Updated**: December 3, 2025

---

## 🎯 Project Overview

This project demonstrates a production-grade **multi-cloud architecture** spanning AWS and GCP with secure cross-cloud connectivity, featuring:

- ✅ **Multi-Cloud Split Architecture**: Data tier (AWS K3s) + Compute tier (GCP GKE)
- ✅ **Encrypted VPN Tunnel**: WireGuard-based secure connectivity between clouds
- ✅ **Distributed Workloads**: Metals price processing pipeline across cloud providers
- ✅ **Kubernetes Secret Management**: Secure handling of VPN cryptographic keys
- ✅ **Cross-Cloud Networking**: Service discovery and routing via VPN
- ✅ **Production Patterns**: Infrastructure as Code, GitOps, security best practices

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CA4 Multi-Cloud Architecture                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────┐         ┌───────────────────────────┐   │
│  │  GCP (us-central1-a)   │         │   AWS (us-east-2)         │   │
│  │  Compute Tier          │         │   Data Tier               │   │
│  ├────────────────────────┤         ├───────────────────────────┤   │
│  │                        │         │                           │   │
│  │  Producer (1/1) ───────┼────┐    │  ┌─── Kafka (1/1)         │   │
│  │  Processor (1/1) ──────┼────┼────┼──┼─── MongoDB (1/1)       │   │
│  │                        │    │    │  │    Zookeeper (1/1)     │   │
│  │  WireGuard VPN ────────┼────┘    │  └─── WireGuard VPN       │   │
│  │  10.200.0.2/24         │ TUNNEL  │       10.200.0.1/24       │   │
│  │                        │         │                           │   │
│  │  GKE Cluster           │         │  K3s Cluster              │   │
│  │  2x e2-standard-2      │         │  1x t3.medium             │   │
│  │  VPC: 10.1.0.0/24      │         │  VPC: 10.0.0.0/16         │   │
│  └────────────────────────┘         └───────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

**Data Flow**:
1. Producer (GCP) → Kafka (AWS) via encrypted VPN tunnel
2. Kafka (AWS) → Processor (GCP) via VPN
3. Processor (GCP) → MongoDB (AWS) via VPN

**Encryption**: All cross-cloud traffic encrypted with WireGuard (ChaCha20-Poly1305)

---

## 📊 Current Status

**Deployment**: ✅ Complete and operational
**VPN Tunnel**: ✅ Encrypted and stable
**Applications**: ✅ Running and processing data
**Secret Management**: ✅ Kubernetes secrets (keys not in Git)

### Running Services

**AWS K3s Cluster (Data Tier)**:
- ✅ Kafka StatefulSet (1/1)
- ✅ MongoDB StatefulSet (1/1)
- ✅ Zookeeper StatefulSet (1/1)
- ✅ WireGuard VPN (1/1)

**GCP GKE Cluster (Compute Tier)**:
- ✅ Producer Deployment (1/1)
- ✅ Processor Deployment (1/1)
- ✅ WireGuard VPN (1/1)

### Recent Achievements
- ✅ Implemented Kubernetes Secrets for WireGuard key management
- ✅ Resolved cross-cloud routing with hostAliases and socat forwarding
- ✅ Documented SSH access strategy (academic vs. enterprise)
- ✅ End-to-end data pipeline operational

---

## 📁 Repository Structure

```
CA4/
├── README.md                              # This file
├── WIREGUARD-DEPLOYMENT-QUICKSTART.md     # Quick VPN deployment reference
├── CA4-DESIGN-DECISIONS.md                # Critical design decisions tracker
│
├── docs/                                  # Documentation
│   ├── DEPLOYMENT-GUIDE.md                # Complete deployment walkthrough
│   ├── WIREGUARD-SECRET-MANAGEMENT.md     # VPN key management strategy
│   ├── SSH-ACCESS-STRATEGY.md             # SSH security documentation
│   ├── setup/                             # Setup guides
│   │   ├── GCP-SETUP-GUIDE.md             # GCP account setup
│   │   └── GCLOUD-SETUP-COMPLETE.md       # gcloud CLI configuration
│   └── archive/                           # Historical documentation
│
├── terraform/                             # Infrastructure as Code
│   ├── main.tf                            # AWS infrastructure
│   ├── variables.tf
│   ├── outputs.tf
│   └── gcp/                               # GCP infrastructure
│       ├── main.tf                        # GKE cluster config
│       ├── variables.tf
│       └── outputs.tf
│
├── k8s/                                   # Kubernetes manifests
│   ├── aws/                               # AWS data tier services
│   │   ├── 01-namespace.yaml
│   │   ├── 02-secrets.yaml
│   │   ├── 03-zookeeper.yaml
│   │   ├── 04-kafka.yaml
│   │   ├── 05-mongodb.yaml
│   │   └── 06-nodeport-services.yaml
│   ├── gcp/                               # GCP compute tier services
│   │   ├── 01-namespace.yaml
│   │   ├── 02-secrets.yaml
│   │   ├── 03-configmaps.yaml
│   │   ├── 04-producer.yaml
│   │   ├── 05-processor.yaml
│   │   └── 0X-wireguard*.yaml             # VPN routing services
│   └── wireguard/                         # VPN configuration
│       ├── wireguard-aws-template.yaml    # AWS VPN (no keys)
│       ├── wireguard-gcp-template.yaml    # GCP VPN (no keys)
│       └── *-configured.yaml              # (gitignored - has keys)
│
├── producer/                              # Producer application
│   ├── Dockerfile
│   ├── producer.py
│   └── requirements.txt
│
├── processor/                             # Processor application
│   ├── Dockerfile
│   ├── processor.py
│   └── requirements.txt
│
├── scripts/                               # Automation scripts
│   ├── deploy-gcp-gke.sh                  # GCP cluster deployment
│   ├── setup-gcloud-env.sh                # GCP environment setup
│   ├── deploy-wireguard-secrets.sh        # VPN secret management
│   └── configure-wireguard.sh             # VPN configuration
│
└── .wireguard-keys.env                    # (gitignored - local keys only)
```

---

## 🚀 Quick Start

### Prerequisites
- AWS account with EC2 access
- GCP account with $300 free credits
- Terraform >= 1.5
- kubectl >= 1.28
- gcloud CLI

### 1. Deploy AWS Infrastructure

```bash
cd terraform
terraform init
terraform apply

# Verify
ssh -i ~/.ssh/ca0-keys.pem ubuntu@<AWS_MASTER_IP> "sudo k3s kubectl get nodes"
```

### 2. Deploy GCP Infrastructure

```bash
cd terraform/gcp
terraform init
terraform apply

# Configure kubectl
source scripts/setup-gcloud-env.sh
gcloud container clusters get-credentials ca4-gke-compute \
  --zone=us-central1-a --project=metals-price-tracker

# Verify
kubectl get nodes
```

### 3. Deploy WireGuard VPN

```bash
# Deploy secrets (keys stored in .wireguard-keys.env, gitignored)
./scripts/deploy-wireguard-secrets.sh aws
./scripts/deploy-wireguard-secrets.sh gcp

# Deploy VPN pods
kubectl apply -f k8s/wireguard/wireguard-aws-template.yaml --context aws
kubectl apply -f k8s/wireguard/wireguard-gcp-template.yaml --context gcp

# Verify tunnel
kubectl exec -n vpn-system deployment/wireguard -- ping -c 4 10.200.0.1
```

### 4. Deploy Applications

```bash
# Deploy to AWS
scp -i ~/.ssh/ca0-keys.pem -r k8s/aws ubuntu@<AWS_IP>:/tmp/
ssh -i ~/.ssh/ca0-keys.pem ubuntu@<AWS_IP> "sudo k3s kubectl apply -f /tmp/aws/"

# Deploy to GCP
kubectl apply -f k8s/gcp/

# Verify data flow
kubectl logs -n ca3-app -l app=producer --tail=20
kubectl logs -n ca3-app -l app=processor --tail=20
```

---

## 📚 Documentation

### Core Documentation
- **[Deployment Guide](docs/DEPLOYMENT-GUIDE.md)** - Complete step-by-step deployment
- **[WireGuard Secret Management](docs/WIREGUARD-SECRET-MANAGEMENT.md)** - VPN key management strategy
- **[WireGuard Quickstart](WIREGUARD-DEPLOYMENT-QUICKSTART.md)** - Quick VPN reference
- **[Design Decisions](CA4-DESIGN-DECISIONS.md)** - Architecture decision record

### Setup Guides
- **[GCP Setup Guide](docs/setup/GCP-SETUP-GUIDE.md)** - GCP account creation
- **[gcloud Setup](docs/setup/GCLOUD-SETUP-COMPLETE.md)** - CLI configuration

### Security Documentation
- **[SSH Access Strategy](docs/SSH-ACCESS-STRATEGY.md)** - SSH security (academic vs. enterprise)

---

## 🛠️ Technology Stack

### Infrastructure
- **AWS**: EC2 (t3.medium), VPC, Security Groups
- **GCP**: GKE (e2-standard-2), VPC, Firewall Rules
- **IaC**: Terraform 1.5+

### Kubernetes
- **Orchestration**: K3s (AWS), GKE (GCP)
- **Networking**: Flannel (AWS), VPC-native (GCP)
- **VPN**: WireGuard (encrypted tunnel)

### Applications
- **Producer**: Python 3.11, Kafka-Python
- **Processor**: Python 3.11, Kafka-Python, PyMongo
- **Messaging**: Apache Kafka 7.5.0 + Zookeeper
- **Database**: MongoDB 7.0

### Security
- **VPN Encryption**: WireGuard (ChaCha20-Poly1305)
- **Secret Management**: Kubernetes Secrets
- **Network Policies**: Firewall rules, security groups
- **Access Control**: SSH key-based authentication

---

## 💰 Cost Estimate

| Resource | Quantity | Cost/Month |
|----------|----------|------------|
| AWS t3.medium | 1 | ~$30 |
| GCP e2-standard-2 | 2 | $0 (free credits) |
| **Total** | | **~$30/month** |

*GCP free during 90-day $300 credit period*

**Assignment Duration (1 month)**: ~$30 total

---

## 🔑 Key Features

### Multi-Cloud Architecture
- Geographical distribution (us-east-2 + us-central1-a)
- Tier separation (data vs. compute)
- Cloud provider diversity (AWS + GCP)

### Secure Networking
- Encrypted VPN tunnel (WireGuard)
- Network segmentation (VPCs, CIDRs)
- Firewall rules and security groups

### DevOps Best Practices
- Infrastructure as Code (Terraform)
- GitOps workflow (Kubernetes manifests)
- Secret management (keys not in Git)
- Documentation as code

### Kubernetes Expertise
- StatefulSets for stateful services
- Cross-cluster service discovery
- ConfigMaps and Secrets
- Resource limits and health checks

---

## 🎓 Learning Outcomes

This project demonstrates mastery of:

1. **Multi-Cloud Architecture** - Designing and deploying across AWS and GCP
2. **Secure Cross-Cloud Networking** - VPN tunnels, routing, service discovery
3. **Kubernetes at Scale** - Managing workloads across multiple clusters
4. **Infrastructure as Code** - Terraform for reproducible infrastructure
5. **DevOps Security** - Secret management, network isolation, access control
6. **Production Patterns** - GitOps, documentation, troubleshooting

---

## 🚨 Important Notes

### Security
- **WireGuard keys** stored in `.wireguard-keys.env` (gitignored)
- **Configured YAML files** with real keys are gitignored
- **Template files** (safe to commit) use init containers to inject secrets at runtime
- **SSH access** currently open for academic project (documented in [SSH-ACCESS-STRATEGY.md](docs/SSH-ACCESS-STRATEGY.md))

### Production Considerations
For production deployment, consider:
- Restricting SSH to VPN or bastion host
- Using cloud-native VPN gateways (AWS VPN, Cloud VPN)
- Implementing External Secrets Operator for secret management
- Adding observability stack (Prometheus, Grafana, Loki)
- Implementing autoscaling (HPA, cluster autoscaler)

---

## 🤝 Contributing

This is a student project for CS 5287. Not accepting external contributions.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 👤 Contact

**Philip Eykamp**
CS 5287 - DevOps Engineering
December 2025

---

**Last Updated**: December 3, 2025
**Version**: 1.0.0
**Status**: ✅ Complete and operational
