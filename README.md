# CA4: Multi-Hybrid Cloud Deployment

**Student**: Philip Eykamp
**Course**: CS 5287 - DevOps Engineering
**Assignment**: CA4 - Multi-Hybrid Cloud Operations
**Submission Date**: November 2025

---

## 🎯 Project Overview

This project extends the CA3 single-cloud Kubernetes deployment to a **multi-cloud architecture**, demonstrating:

- ✅ **Multi-Cloud Deployment**: AWS + [Second Cloud TBD] with cross-cloud connectivity
- ✅ **Secure VPN Tunnel**: WireGuard-based encrypted connectivity between clouds
- ✅ **Distributed Workloads**: Data tier in AWS, compute tier in Cloud2
- ✅ **Unified Observability**: Centralized monitoring and logging across clouds
- ✅ **Resilience Testing**: VPN failure scenario with automated recovery
- ✅ **Production Patterns**: Industry-standard multi-cloud architecture

---

## 🏗️ Architecture (Planned)

```
AWS (us-east-2)                          Cloud2 (TBD)
┌──────────────────────────┐            ┌──────────────────────────┐
│ DATA TIER                │            │ COMPUTE TIER             │
│                          │            │                          │
│ • Kafka StatefulSet      │◄──────────┤ • Producer Deployment    │
│ • Zookeeper StatefulSet  │  WireGuard │ • Processor Deployment   │
│ • MongoDB StatefulSet    │  VPN       │                          │
│                          │  Tunnel    │ • Promtail (logs)        │
│ OBSERVABILITY HUB        │            │ • Node Exporter (metrics)│
│ • Prometheus             │◄───────────┤                          │
│ • Grafana                │            │                          │
│ • Loki                   │            │                          │
└──────────────────────────┘            └──────────────────────────┘
     Existing CA3                            New in CA4
```

**Data Flow**:
1. Producer (Cloud2) → Kafka (AWS) via VPN tunnel
2. Processor (Cloud2) → Kafka (AWS) → MongoDB (AWS) via VPN
3. Promtail (Cloud2) → Loki (AWS) centralized logging
4. Prometheus (AWS) scrapes metrics from both clouds

---

## 📊 Current Status

**Status**: 🟢 **Infrastructure Development**

### Completed
- ✅ CA3 baseline deployed and operational (AWS Kubernetes cluster)
- ✅ Design decisions finalized ([CA4-DESIGN-DECISIONS.md](CA4-DESIGN-DECISIONS.md))
  - Cloud Provider: **GCP** (Google Kubernetes Engine)
  - Topology: **Multi-Cloud Split** (data in AWS, compute in GCP)
  - Connectivity: **WireGuard VPN** ($0 cost)
  - Distribution: Kafka/MongoDB (AWS), Producer/Processor (GCP)
  - Failure Scenario: VPN tunnel failure with recovery
- ✅ Repository structure cleaned and organized
- ✅ GCP account setup completed
- ✅ GCP Terraform configuration created ([terraform/gcp/](terraform/gcp/))

### In Progress
- 🟡 Ready to deploy GCP GKE cluster

### Pending
- ⏳ Deploy GCP infrastructure (terraform apply)
- ⏳ WireGuard VPN setup (AWS ↔ GCP)
- ⏳ Deploy applications to GCP
- ⏳ Cross-cloud observability configuration
- ⏳ Resilience testing and documentation

---

## 📁 Repository Structure

```
CA4/
├── README.md                          # This file
├── CA4-DESIGN-DECISIONS.md            # Critical design decisions tracker
├── LICENSE                            # MIT License
│
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                        # AWS VPC, EC2, security groups (data tier)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user-data-master.sh            # K3s master bootstrap
│   ├── user-data-worker.sh            # K3s worker bootstrap
│   └── gcp/                           # GCP GKE infrastructure (compute tier)
│       ├── main.tf                    # GKE cluster, VPC, firewall rules
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars           # GCP credentials (gitignored)
│       └── README.md                  # GCP deployment guide
│
├── k8s/                               # Kubernetes manifests
│   ├── base/                          # Core application (CA3)
│   │   ├── 00-namespace.yaml
│   │   ├── 10-zookeeper.yaml
│   │   ├── 11-kafka.yaml
│   │   ├── 12-mongodb.yaml
│   │   ├── 20-processor.yaml
│   │   └── 21-producer.yaml
│   ├── observability/                 # Prometheus, Grafana, Loki
│   │   ├── prometheus-values.yaml
│   │   ├── loki-values.yaml
│   │   └── metals-sli-dashboard.json
│   └── security/                      # NetworkPolicies
│       └── network-policies.yaml
│
├── producer/                          # Producer application
│   ├── Dockerfile
│   ├── producer.py
│   └── requirements.txt
│
├── processor/                         # Processor application
│   ├── Dockerfile
│   ├── processor.py
│   └── requirements.txt
│
├── mongodb/                           # MongoDB initialization
│   └── init-db.js
│
└── scripts/                           # Automation scripts
    ├── build-images.sh
    ├── setup-k3s-cluster.sh
    ├── deploy-aws-k3s.sh
    ├── deploy-gcp-gke.sh              # GCP GKE deployment
    ├── verify-observability.sh
    ├── load-test.sh
    └── resilience-test.sh
```

---

## 🚀 Quick Start (Coming Soon)

Once design decisions are finalized, the deployment will follow these steps:

### 1. Deploy AWS Cluster (CA3 Baseline)
```bash
cd terraform
terraform init
terraform apply

# Configure kubectl
../scripts/setup-k3s-cluster.sh

# Deploy application + observability
kubectl apply -k k8s/base/
helm install prometheus prometheus-community/kube-prometheus-stack -n ca3-app
```

### 2. Deploy Second Cloud Cluster
```bash
cd terraform/cloud2
terraform init
terraform apply

# Configure second cluster kubeconfig
# (Details TBD based on cloud provider choice)
```

### 3. Establish VPN Tunnel
```bash
# Deploy WireGuard VPN in both clusters
./scripts/setup-wireguard.sh

# Verify connectivity
kubectl exec -it <producer-pod> -n ca3-app -- ping <kafka-service-aws>
```

### 4. Deploy Applications to Cloud2
```bash
# Deploy producers and processors to Cloud2
kubectl apply -f k8s/cloud2/ --context=cloud2

# Verify cross-cloud connectivity
./scripts/verify-multi-cloud.sh
```

### 5. Test Resilience
```bash
# Run VPN failure scenario
./scripts/ca4-resilience-test.sh
```

---

## 🔑 Key Design Decisions

See [CA4-DESIGN-DECISIONS.md](CA4-DESIGN-DECISIONS.md) for detailed analysis. Summary:

| Decision | Status | Leading Option |
|----------|--------|----------------|
| **Cloud Provider** | 🔴 Pending | DigitalOcean (cost) or GCP (learning) |
| **Topology** | 🔴 Pending | Multi-Cloud Split (data in AWS, compute in Cloud2) |
| **Connectivity** | 🔴 Pending | WireGuard VPN ($0 cost) |
| **Distribution** | 🔴 Pending | Kafka/MongoDB in AWS, Producer/Processor in Cloud2 |
| **Failure Scenario** | 🔴 Pending | VPN tunnel failure with recovery |

---

## 💰 Estimated Costs

### Option 1: AWS + DigitalOcean (Most Cost-Effective)
- **AWS**: 2 nodes (master + worker-1) = $60/month
- **DigitalOcean**: 2 nodes (compute tier) = $0 for 2 months (credits), then $40/month
- **VPN**: $0 (WireGuard on existing nodes)
- **Total**: $60/month during free tier, $100/month after

### Option 2: AWS + GCP (Best for Learning)
- **AWS**: 2 nodes = $60/month
- **GCP**: 2 nodes = $0 for 3 months (credits), then $60/month
- **VPN**: $0 (WireGuard)
- **Total**: $60/month during free tier, $120/month after

**Assignment Duration**: ~1 month = **$60-75 total cost**

---

## 🛠️ Technology Stack

### Infrastructure
- **AWS**: EC2 (t3.medium), VPC, Security Groups
- **Cloud2**: TBD (GCP GKE or DigitalOcean DOKS)
- **IaC**: Terraform 1.5+

### Kubernetes
- **Orchestration**: K3s (lightweight Kubernetes)
- **CNI**: Flannel
- **Ingress**: Traefik (K3s default)

### Applications
- **Producer**: Python 3.11, Kafka-Python, Prometheus-Client
- **Processor**: Python 3.11, Kafka-Python, PyMongo, Prometheus-Client
- **Messaging**: Apache Kafka 7.5.0 + Zookeeper
- **Database**: MongoDB 7.0 (with TLS)

### Observability
- **Metrics**: Prometheus, Grafana
- **Logging**: Loki, Promtail
- **Dashboards**: Custom SLI dashboard (16 panels)

### Security
- **VPN**: WireGuard (ChaCha20 encryption)
- **Network**: NetworkPolicies (9 policies)
- **Secrets**: External Secrets Operator + AWS Secrets Manager
- **TLS**: MongoDB (preferTLS), Kafka (dual listeners)

---

## 📚 Documentation

- [CA4-DESIGN-DECISIONS.md](CA4-DESIGN-DECISIONS.md) - Comprehensive design decisions tracker
- [CA4-CLEANUP-PLAN.md](CA4-CLEANUP-PLAN.md) - Repository cleanup plan (CA3 → CA4)

**Coming Soon**:
- CA4-DEPLOYMENT-GUIDE.md - Step-by-step deployment instructions
- CA4-ARCHITECTURE.md - Detailed architecture diagrams
- CA4-RESILIENCE-TEST.md - Failure scenario runbook

---

## 🎓 Learning Objectives

This project demonstrates understanding of:

1. **Multi-Cloud Architecture**: Designing systems across multiple cloud providers
2. **Cross-Cloud Networking**: Secure VPN tunnels, service discovery, routing
3. **Distributed Systems**: Data consistency, latency considerations, failure modes
4. **DevOps Automation**: Infrastructure as Code across multiple clouds
5. **Observability**: Unified monitoring and logging in distributed environments
6. **Resilience Engineering**: Designing for and testing failure scenarios

---

## 📝 CA3 Baseline

This project builds on CA3, which implemented:
- ✅ Production Kubernetes cluster on AWS (3 nodes, 10GB RAM)
- ✅ Full observability stack (Prometheus, Grafana, Loki)
- ✅ Autoscaling (HPA for Producer/Processor)
- ✅ Security hardening (NetworkPolicies, TLS, External Secrets)
- ✅ Comprehensive documentation and evidence

**CA3 Status**: All 17 pods operational, full observability, passing all requirements.

**CA4 Goal**: Extend to multi-cloud while maintaining all CA3 capabilities.

---

## 🤝 Contributing

This is a student project for CS 5287. Not accepting contributions.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 👤 Contact

**Philip Eykamp**
CS 5287 - DevOps Engineering
November 2025

---

**Last Updated**: November 13, 2025
**Version**: 0.1.0 (Planning Phase)
**Status**: 🟡 Awaiting design decision approvals
