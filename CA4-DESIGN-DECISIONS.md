# CA4 Multi-Hybrid Cloud - Design Decisions Tracker

**Student**: Philip Eykamp
**Course**: CS 5287
**Assignment**: CA4 - Multi-Hybrid Cloud Deployment
**Date**: November 2025

---

## Executive Summary

This document tracks all critical design decisions for CA4, building on the existing CA3 AWS Kubernetes infrastructure. The goal is to extend to a multi-cloud deployment demonstrating cross-cloud connectivity, resilience, and operational excellence.

---

## CA3 Baseline (What We're Building On)

### Current Infrastructure
- **Platform**: K3s on AWS (us-east-2)
- **Nodes**: 3 nodes (2x t3.medium + 1x t3.small) = 10GB RAM total
- **Cost**: ~$75/month (~$2.50/day)
- **Status**: ✅ All services operational

### Current Components (AWS)
```
AWS K3s Cluster:
├── Data Layer (Worker-1, t3.medium)
│   ├── Kafka StatefulSet (1 replica, 1.5GB RAM, TLS ready)
│   ├── Zookeeper StatefulSet (1 replica, 512MB RAM)
│   └── MongoDB StatefulSet (1 replica, 1GB RAM, TLS enabled)
│
├── Application Layer (Worker-2, t3.small)
│   ├── Producer Deployment (1-3 replicas via HPA)
│   └── Processor Deployment (1-3 replicas via HPA)
│
└── Observability (Master, t3.medium)
    ├── Prometheus + Grafana
    ├── Loki + Promtail
    └── External Secrets Operator
```

### Existing Features
- ✅ Full observability (Prometheus, Grafana, Loki)
- ✅ Autoscaling (HPA for Producer/Processor)
- ✅ TLS encryption (MongoDB + Kafka dual listeners)
- ✅ Network policies (9 policies deployed)
- ✅ Secrets management (External Secrets Operator + AWS Secrets Manager)

---

## DECISION FRAMEWORK

For each decision below:
- **STATUS**: 🔴 Pending | 🟡 Under Review | 🟢 Decided
- **DECISION DATE**: When finalized
- **RATIONALE**: Why this choice
- **IMPACT**: Cost, complexity, timeline
- **ALTERNATIVES CONSIDERED**: What else was evaluated

---

## 🔴 DECISION 1: Second Cloud Provider Selection

**STATUS**: 🔴 Pending
**PRIORITY**: Critical (blocks all other decisions)
**DECISION NEEDED BY**: Before infrastructure provisioning

### Options Analysis

#### Option A: Google Cloud Platform (GCP) ⭐ RECOMMENDED FOR LEARNING
**Free Tier**: $300 credit (90 days)
**Cost After Credits**: ~$60/month for GKE cluster

**Pros**:
- Excellent Kubernetes (GKE) - native platform, similar to AWS EKS
- Strong VPN support (Cloud VPN with HA options)
- $300 free credit = 3-5 months free for small cluster
- Industry leader - best for resume/portfolio
- Similar AWS experience (IaC friendly)
- Strong network performance
- Good Terraform provider

**Cons**:
- Credit card required
- Credits expire after 90 days (must monitor)
- More expensive after credits (~$60/month)
- Learning curve for GCP-specific services

**Total CA4 Cost** (with credits):
- AWS: $75/month (existing)
- GCP: $0/month for 3 months, then $60/month
- **Total**: $75/month (during free tier), $135/month after

---

#### Option B: Azure
**Free Tier**: $200 credit (30 days) + 12 months free services
**Cost After Credits**: ~$55/month for AKS cluster

**Pros**:
- Mature AKS (Azure Kubernetes Service)
- $200 credit + 12 months free tier for some services
- Good enterprise integration (if targeting corporate jobs)
- Strong Terraform support

**Cons**:
- Credit card required
- More complex networking than GCP/AWS
- Only 30 days of credits (vs GCP's 90)
- Steeper learning curve (different terminology)
- VPN setup more complex

**Total CA4 Cost**:
- AWS: $75/month
- Azure: $0 first month, then ~$55/month
- **Total**: $75/month (first month), $130/month after

---

#### Option C: DigitalOcean 💰 RECOMMENDED FOR COST
**Free Tier**: $200 credit (60 days) with promo codes
**Cost After Credits**: ~$40/month for DOKS cluster

**Pros**:
- Simplest pricing model (very transparent)
- Managed Kubernetes (DOKS) is straightforward
- Very good documentation (beginner-friendly)
- No credit card needed for trial (with promo codes)
- Lowest cost after credits (~$40/month vs $55-60)
- Simple VPN setup (DigitalOcean VPN or WireGuard)
- Fast provisioning (minutes vs AWS/GCP)

**Cons**:
- Smaller ecosystem than AWS/GCP/Azure
- Less enterprise features (may not matter for assignment)
- Not as "impressive" on resume as GCP/AWS

**Total CA4 Cost** (with credits):
- AWS: $75/month
- DO: $0 for 2 months, then $40/month
- **Total**: $75/month (during free tier), $115/month after

---

#### Option D: Linode (Akamai)
**Free Tier**: $100 credit (60 days)
**Cost After Credits**: ~$35-50/month

**Pros**:
- Simple pricing
- Good documentation
- Managed Kubernetes (LKE)

**Cons**:
- Smaller ecosystem than others
- Less industry recognition
- Lower credit amount ($100 vs $200-300)

**Total CA4 Cost**:
- AWS: $75/month
- Linode: $0 for 2 months, then $35-50/month
- **Total**: $75/month (during free tier), $110-125/month after

---

### Decision Matrix

| Factor | GCP | Azure | DigitalOcean | Linode |
|--------|-----|-------|--------------|--------|
| **Free Credits** | $300 (90d) | $200 (30d) | $200 (60d) | $100 (60d) |
| **Free Duration** | 3 months | 1 month | 2 months | 2 months |
| **Cost After Credits** | $60/mo | $55/mo | $40/mo | $35-50/mo |
| **Learning Value** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Resume Value** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Ease of Setup** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Documentation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Kubernetes Quality** | ⭐⭐⭐⭐⭐ (GKE) | ⭐⭐⭐⭐ (AKS) | ⭐⭐⭐⭐ (DOKS) | ⭐⭐⭐⭐ (LKE) |

---

### My Recommendation

**FOR LEARNING/CAREER**: GCP (Option A)
- Best multi-cloud experience (AWS + GCP = 2 major cloud providers)
- Longest free tier (90 days)
- Industry standard skills
- Best for portfolio/resume

**FOR COST**: DigitalOcean (Option C)
- Lowest long-term cost ($115/mo vs $135/mo for GCP)
- Simplest setup = less debugging time
- Still demonstrates multi-cloud patterns
- Good enough for assignment requirements

**DECISION**: ❓ **PENDING USER INPUT**

---

## 🔴 DECISION 2: Topology Pattern

**STATUS**: 🔴 Pending
**PRIORITY**: Critical (affects component distribution)
**DECISION NEEDED BY**: Before deployment planning

### Option A: Multi-Cloud Split (Data vs Compute) ⭐ RECOMMENDED

```
AWS (us-east-2):                      GCP/DO (Cloud2):
┌─────────────────────────┐          ┌─────────────────────────┐
│ DATA TIER               │          │ COMPUTE TIER            │
│                         │          │                         │
│ • Kafka StatefulSet     │◄────────┤ • Producer Deployment   │
│   (3 replicas)          │  VPN    │   (1-3 replicas)        │
│                         │  Tunnel │                         │
│ • Zookeeper StatefulSet │          │ • Processor Deployment  │
│   (1 replica)           │          │   (1-3 replicas)        │
│                         │          │                         │
│ • MongoDB StatefulSet   │◄─────────┤                         │
│   (1 replica)           │          │                         │
│                         │          │ OBSERVABILITY           │
│ OBSERVABILITY HUB       │          │ • Promtail (logs)       │
│ • Prometheus            │◄─────────┤ • Node Exporter         │
│ • Grafana               │          │                         │
│ • Loki                  │          │                         │
└─────────────────────────┘          └─────────────────────────┘
        Existing CA3                       New in CA4
```

**Data Flow**:
1. Producer (Cloud2) → Kafka (AWS) via VPN
2. Processor (Cloud2) → Kafka (AWS) → MongoDB (AWS) via VPN
3. Promtail (Cloud2) → Loki (AWS) via VPN
4. Prometheus (AWS) scrapes both clouds

**Pros**:
- ✅ Clean separation of concerns (data persistence vs compute)
- ✅ Demonstrates cross-cloud connectivity clearly
- ✅ Reuses existing CA3 AWS infrastructure (Kafka, MongoDB, observability)
- ✅ Clear failure scenario (VPN down → processors can't reach Kafka)
- ✅ Realistic pattern (centralized data, distributed compute)
- ✅ Easy to understand and explain

**Cons**:
- ❌ Higher latency (Kafka ↔ Processor cross-cloud)
- ❌ More network bandwidth usage
- ❌ VPN dependency (single point of failure)

**Failure Scenario**:
```bash
# Simulate VPN tunnel failure
kubectl delete -n kube-system deployment/wireguard

# Observe:
# - Processors in Cloud2 can't reach Kafka in AWS
# - Producer messages queue up or fail
# - Grafana dashboard shows connection errors

# Recovery:
kubectl apply -f wireguard.yaml
# - VPN tunnel re-establishes
# - Processors reconnect to Kafka
# - Messages resume processing
```

---

### Option B: Edge → Cloud

```
Local (Your Laptop):                 AWS (us-east-2):
┌─────────────────────────┐          ┌─────────────────────────┐
│ EDGE TIER               │          │ CLOUD TIER              │
│                         │          │                         │
│ • Producer (Docker/K3s) ├─────────►│ • Kafka StatefulSet     │
│                         │  VPN/SSH │ • MongoDB StatefulSet   │
│                         │  Tunnel  │ • Processor Deployment  │
│                         │          │                         │
│                         │          │ • Prometheus            │
│                         │          │ • Grafana               │
│                         │          │ • Loki                  │
└─────────────────────────┘          └─────────────────────────┘
```

**Pros**:
- ✅ Lowest cost (only one cloud + local)
- ✅ Demonstrates edge computing pattern (IoT scenario)
- ✅ Easy to test locally
- ✅ Can simulate edge device scenarios

**Cons**:
- ❌ Requires laptop always on during testing
- ❌ NAT traversal complexity (firewall issues)
- ❌ Less impressive than multi-cloud
- ❌ Not truly "multi-cloud" (may not meet assignment requirements)
- ❌ Network reliability dependent on home internet

---

### Option C: Active-Active Multi-Cloud

```
AWS (us-east-2):                      GCP (Cloud2):
┌─────────────────────────┐          ┌─────────────────────────┐
│ CLUSTER 1               │          │ CLUSTER 2               │
│                         │◄────────►│                         │
│ • Kafka-1               │ Mirroring│ • Kafka-2               │
│ • MongoDB-1 (Primary)   │ Replicat │ • MongoDB-2 (Secondary) │
│ • Producer-1            │          │ • Producer-2            │
│ • Processor-1           │          │ • Processor-2           │
│                         │          │                         │
│ • Prometheus            │          │ • Prometheus            │
│ • Grafana               │          │ • Grafana               │
└─────────────────────────┘          └─────────────────────────┘
```

**Pros**:
- ✅ Most resilient (true HA)
- ✅ True multi-cloud HA
- ✅ Geographic distribution
- ✅ Impressive technically

**Cons**:
- ❌ Most complex setup
- ❌ Kafka MirrorMaker is challenging
- ❌ MongoDB replica set across clouds (latency issues)
- ❌ Double the cost (running full stack in both clouds)
- ❌ Overkill for assignment (may not be graded higher)

---

### Decision Matrix

| Factor | Multi-Cloud Split | Edge→Cloud | Active-Active |
|--------|------------------|------------|---------------|
| **Complexity** | Medium | Low | Very High |
| **Cost** | Medium | Low | High (2x) |
| **Learning Value** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Assignment Fit** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Clear Demo** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Reliability** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Setup Time** | 4-6 hours | 2-3 hours | 12-16 hours |

---

### My Recommendation

**RECOMMENDED**: Option A - Multi-Cloud Split

**Rationale**:
- Best balance of complexity vs demonstration value
- Clearly shows multi-cloud connectivity (assignment goal)
- Reuses CA3 infrastructure (efficient)
- Easy to explain and demonstrate
- Realistic failure scenario
- Achievable within assignment timeline

**DECISION**: ❓ **PENDING USER INPUT**

---

## 🔴 DECISION 3: Connectivity Model

**STATUS**: 🔴 Pending
**PRIORITY**: Critical (core infrastructure)
**DECISION NEEDED BY**: Before network setup

### Option A: Site-to-Site VPN with WireGuard ⭐ RECOMMENDED

**Implementation**:
```
AWS VPC                               GCP/DO VPC
┌─────────────────────┐              ┌─────────────────────┐
│                     │              │                     │
│  WireGuard Pod      │◄────────────►│  WireGuard Pod      │
│  (10.0.1.100:51820) │  UDP 51820  │  (10.1.1.100:51820) │
│        ↓            │              │        ↓            │
│  K8s Services       │              │  K8s Services       │
│  (10.43.0.0/16)     │              │  (10.44.0.0/16)     │
└─────────────────────┘              └─────────────────────┘
```

**WireGuard Configuration**:
```ini
# AWS side (wg0.conf)
[Interface]
PrivateKey = <aws-private-key>
Address = 10.100.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <gcp-public-key>
Endpoint = <gcp-public-ip>:51820
AllowedIPs = 10.100.0.2/32, 10.44.0.0/16
PersistentKeepalive = 25
```

**Pros**:
- ✅ Industry standard VPN protocol
- ✅ **Zero cost** (no VPN gateway fees)
- ✅ Encrypted automatically (ChaCha20)
- ✅ Very fast (kernel-level, minimal overhead)
- ✅ Simple configuration (vs IPsec)
- ✅ Works with any cloud provider
- ✅ Easy to automate with Kubernetes manifests
- ✅ Great for demonstration (show config, test connectivity)

**Cons**:
- ❌ Requires manual key management (but scriptable)
- ❌ Not "managed" (but more control)
- ❌ Need to deploy WireGuard pods in both clusters

**Cost**:
- AWS: $0 (runs on existing nodes)
- GCP/DO: $0 (runs on existing nodes)
- **Total**: $0/month

**Setup Complexity**: Medium (4-5 hours)
- Generate WireGuard keys
- Deploy pods in both clusters
- Configure allowed IPs and routing
- Test connectivity

---

### Option B: AWS VPN Gateway + Cloud VPN

**Implementation**:
```
AWS VPN Gateway                       GCP Cloud VPN
($0.05/hour = $36/month)             ($0.05/hour = $36/month)
        ↓                                     ↓
    AWS VPC                               GCP VPC
```

**Pros**:
- ✅ Managed service (AWS + GCP handle it)
- ✅ Built-in monitoring
- ✅ HA options available
- ✅ Enterprise-grade

**Cons**:
- ❌ **Expensive**: $72/month ($36 AWS + $36 GCP)
- ❌ Complex setup (IPsec config, BGP)
- ❌ Overkill for assignment
- ❌ Not supported by all cloud providers (e.g., DigitalOcean)

**Cost**:
- AWS VPN Gateway: $36/month
- GCP Cloud VPN: $36/month (if GCP) or N/A (if DigitalOcean)
- **Total**: $72/month (if GCP), N/A (if DO)

---

### Option C: Service Mesh (Istio Multi-Cluster)

**Implementation**:
```
AWS K8s + Istio                       GCP K8s + Istio
┌─────────────────────┐              ┌─────────────────────┐
│ Istio Control Plane │◄────────────►│ Istio Control Plane │
│        ↓            │  mTLS        │        ↓            │
│ Istio Sidecar Proxy │              │ Istio Sidecar Proxy │
│        ↓            │              │        ↓            │
│  Application Pods   │              │  Application Pods   │
└─────────────────────┘              └─────────────────────┘
```

**Pros**:
- ✅ Very impressive technically
- ✅ Built-in observability (tracing, metrics)
- ✅ Automatic mTLS (service-to-service encryption)
- ✅ Cross-cluster service discovery
- ✅ Traffic management (retries, circuit breakers)

**Cons**:
- ❌ **Very complex** setup (steep learning curve)
- ❌ Resource overhead (2-3 GB RAM per cluster for Istio)
- ❌ May not fit in free tiers (need larger nodes)
- ❌ Long setup time (8-12 hours for multi-cluster)
- ❌ Overkill for assignment (may not get extra credit)

**Cost**:
- No direct cost, but requires larger nodes
- Estimated: +$20-30/month per cloud (larger instances)

---

### Option D: Bastion + SSH Tunnels

**Implementation**:
```bash
# On local machine
ssh -L 9092:kafka-0.ca3-app:9092 ubuntu@aws-bastion
ssh -L 27017:mongodb-0.ca3-app:27017 ubuntu@gcp-bastion

# Applications connect to localhost:9092, localhost:27017
```

**Pros**:
- ✅ **Cheapest** ($0)
- ✅ Simple to understand
- ✅ Works with any cloud
- ✅ No VPN setup needed

**Cons**:
- ❌ Not production-grade (manual tunnel management)
- ❌ Tunnels can drop (need monitoring/restart)
- ❌ Doesn't work for pod-to-pod (only local machine to pod)
- ❌ Not suitable for automated systems
- ❌ Doesn't demonstrate cloud networking skills

---

### Decision Matrix

| Factor | WireGuard VPN | AWS/GCP VPN | Istio Mesh | SSH Tunnels |
|--------|---------------|-------------|------------|-------------|
| **Cost** | $0 | $72/mo | $20-30/mo | $0 |
| **Complexity** | Medium | High | Very High | Low |
| **Setup Time** | 4-5 hours | 6-8 hours | 12-16 hours | 1 hour |
| **Production-Grade** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Learning Value** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Assignment Fit** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| **Automatable** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

---

### My Recommendation

**RECOMMENDED**: Option A - WireGuard VPN

**Rationale**:
- **Best cost/value**: $0 vs $72/month for managed VPN
- **Industry standard**: WireGuard is modern, widely used
- **Automatable**: Can deploy via Kubernetes manifests
- **Perfect for demo**: Easy to show, test, and fail/recover
- **Works with any cloud**: DigitalOcean, GCP, Azure, etc.

**DECISION**: ❓ **PENDING USER INPUT**

---

## 🔴 DECISION 4: Component Distribution

**STATUS**: 🔴 Pending (depends on Topology choice)
**PRIORITY**: High
**DECISION NEEDED BY**: Before deployment planning

### Recommended Distribution (Based on Multi-Cloud Split)

#### AWS Cluster (Keep Existing CA3)

**Data Layer** (Worker-1, t3.medium, 4GB RAM):
- ✅ Kafka StatefulSet (1-3 replicas) - 1.5GB RAM
- ✅ Zookeeper StatefulSet (1 replica) - 512MB RAM
- ✅ MongoDB StatefulSet (1 replica) - 1GB RAM

**Observability Hub** (Master, t3.medium, 4GB RAM):
- ✅ Prometheus (1GB RAM) - Scrapes both clouds
- ✅ Grafana (256MB RAM) - Unified dashboard
- ✅ Loki (512MB RAM) - Centralized logging
- ✅ Alertmanager, Node Exporter

**Why Keep in AWS**:
- Data services benefit from being co-located (Kafka ↔ MongoDB low latency)
- Observability hub centralized for easier management
- Already deployed and working (CA3)

---

#### Cloud2 Cluster (GCP/DO - New for CA4)

**Compute Layer** (2 nodes, e.g., 2x e2-small or DO 2x $12/mo droplets):
- ➕ Producer Deployment (1-3 replicas via HPA) - 128MB RAM each
- ➕ Processor Deployment (1-3 replicas via HPA) - 256MB RAM each
- ➕ Promtail DaemonSet - Ship logs to AWS Loki
- ➕ Node Exporter - Metrics to AWS Prometheus
- ➕ WireGuard VPN pod

**Why in Cloud2**:
- Demonstrates cross-cloud connectivity (main goal)
- Stateless components (easy to scale/migrate)
- Lower resource requirements (smaller nodes OK)
- Clear failure scenario (VPN down = processors fail)

---

### Data Flow

```
Cloud2 (GCP/DO)                       AWS (us-east-2)
─────────────────                     ───────────────
Producer
  ↓
  ├──[VPN]─────────────────────────► Kafka
                                        ↓
                                      (topic: metals-pricing)
                                        ↓
Processor ◄───[VPN]────────────────── Kafka
  ↓
  ├──[VPN]─────────────────────────► MongoDB

Promtail ───[VPN]─────────────────────► Loki (logs)
Node Exp ───[VPN]─────────────────────► Prometheus (metrics)
```

---

### Resource Requirements

**AWS (Existing)**:
- Master: t3.medium (4GB) - No change
- Worker-1: t3.medium (4GB) - No change
- Worker-2: t3.small (2GB) - **Can remove** (apps move to Cloud2)

**Cloud2 (New)**:
- Node-1: 2GB RAM (Producer + WireGuard)
- Node-2: 2GB RAM (Processor + Promtail)
- Total: 4GB RAM minimum

**Cost Impact**:
- AWS: Remove worker-2 → Save $15/month → New AWS cost: $60/month
- Cloud2: 2 nodes × $20/month = $40/month (DigitalOcean example)
- **Total CA4 Cost**: $60 (AWS) + $40 (DO) = **$100/month**

---

### Alternative Distribution (if budget concern)

**Keep All Data + Observability in AWS**:
- Keep all 3 AWS nodes (don't change CA3)
- **Cloud2**: Only 1 node (2GB RAM) running Producer + Processor

**Cost**:
- AWS: $75/month (no change)
- Cloud2: $20/month (1 small node)
- **Total**: $95/month

---

### My Recommendation

**Option 1** (Optimized):
- AWS: 2 nodes (master + worker-1) = $60/month
- Cloud2: 2 nodes (producers + processors) = $40/month
- **Total**: $100/month

**Rationale**:
- Clean separation (data in AWS, compute in Cloud2)
- Saves $15/month by removing AWS worker-2
- Clear multi-cloud demo

**DECISION**: ❓ **PENDING USER INPUT**

---

## 🔴 DECISION 5: Failure Scenario for Resilience Drill

**STATUS**: 🔴 Pending
**PRIORITY**: Medium
**DECISION NEEDED BY**: Before deployment (design system to test)

### Option A: VPN Tunnel Failure ⭐ RECOMMENDED

**Scenario**:
```bash
# 1. System running normally
kubectl get pods -n ca3-app --context=aws
kubectl get pods -n ca3-app --context=gcp

# 2. Grafana shows healthy metrics across both clouds
open http://localhost:3000

# 3. Kill VPN tunnel
kubectl delete deployment wireguard -n kube-system --context=aws

# 4. Observe failures:
# - Processors (Cloud2) can't reach Kafka (AWS)
# - Producer (Cloud2) can't send messages
# - Grafana shows connection errors, message lag increases
# - Loki stops receiving logs from Cloud2

# 5. Recovery:
kubectl apply -f wireguard.yaml --context=aws

# 6. Verify:
# - VPN re-establishes
# - Processors reconnect
# - Message backlog processes
# - Metrics/logs resume
```

**What This Tests**:
- ✅ Cross-cloud connectivity dependency
- ✅ Graceful degradation (queued messages)
- ✅ Observability during failure (Grafana alerts)
- ✅ Recovery automation
- ✅ Clear cause/effect (VPN down = Cloud2 can't reach AWS)

**Pros**:
- ✅ Tests core CA4 requirement (multi-cloud connectivity)
- ✅ Realistic scenario (network partitions happen)
- ✅ Easy to demonstrate (clear failure, clear recovery)
- ✅ Non-destructive (just restart VPN)

**Cons**:
- ❌ Doesn't test cloud provider failure (more dramatic scenario)

---

### Option B: Entire Cloud Region Failure

**Scenario**:
```bash
# 1. Simulate entire AWS region failure
kubectl delete namespace ca3-app --context=aws

# 2. Observe:
# - All data services down (Kafka, MongoDB)
# - Processors (Cloud2) have nothing to do
# - Grafana down (if in AWS)

# 3. Recovery:
kubectl apply -k k8s/base/ --context=aws

# 4. Wait for:
# - Pods to restart
# - PVCs to reattach
# - Data to be accessible again
```

**What This Tests**:
- ✅ Complete regional failure
- ✅ Recovery from total outage

**Pros**:
- ✅ Dramatic demonstration
- ✅ Tests disaster recovery

**Cons**:
- ❌ Too catastrophic (everything fails)
- ❌ Doesn't highlight multi-cloud benefit
- ❌ Recovery is just "bring AWS back" (not interesting)

---

### Option C: Network Partition (Partial Failure)

**Scenario**:
```bash
# 1. Block specific ports via NetworkPolicy
kubectl apply -f block-kafka-port.yaml --context=aws

# 2. Observe:
# - Processors can ping AWS, but can't reach Kafka port 9092
# - Subtle failure (not obvious)

# 3. Debugging exercise:
# - Check logs
# - Test connectivity
# - Identify blocked port

# 4. Recovery:
kubectl delete networkpolicy block-kafka --context=aws
```

**What This Tests**:
- ✅ Troubleshooting skills
- ✅ Observability (logs, metrics help diagnose)
- ✅ NetworkPolicy understanding

**Pros**:
- ✅ More realistic (subtle failures)
- ✅ Shows troubleshooting process

**Cons**:
- ❌ Less dramatic for video demo
- ❌ Harder to explain in short demo

---

### Option D: Cloud2 Node Failure (Kubernetes Self-Healing)

**Scenario**:
```bash
# 1. Delete processor pod
kubectl delete pod -n ca3-app -l app=processor --context=gcp

# 2. Observe:
# - Kubernetes recreates pod automatically
# - Messages queue in Kafka during downtime
# - HPA may scale up if needed

# 3. Verify:
# - New pod comes up
# - Resumes processing
# - Message lag decreases
```

**What This Tests**:
- ✅ Kubernetes self-healing
- ✅ Pod-level resilience

**Pros**:
- ✅ Shows K8s resilience
- ✅ Fast recovery (30-60 seconds)

**Cons**:
- ❌ Doesn't test multi-cloud aspect (could do in CA3)
- ❌ Already demonstrated in CA3 resilience video

---

### Decision Matrix

| Scenario | Multi-Cloud Focus | Realism | Demo Value | Setup Complexity |
|----------|------------------|---------|-----------|-----------------|
| **VPN Failure** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Low |
| **Region Failure** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Low |
| **Network Partition** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Medium |
| **Pod Failure** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Low |

---

### My Recommendation

**RECOMMENDED**: Option A - VPN Tunnel Failure

**Rationale**:
- Best demonstrates CA4 multi-cloud connectivity
- Clear cause and effect (easy to explain)
- Realistic scenario (network failures are common)
- Shows observability working (Grafana catches it)
- Fast recovery (good for video demo)

**DECISION**: ❓ **PENDING USER INPUT**

---

## 📊 Cost Summary (All Options)

### Scenario 1: GCP + WireGuard VPN + Multi-Cloud Split

| Component | Cost/Month | Duration | Total Cost |
|-----------|-----------|----------|-----------|
| AWS (2 nodes: master + worker-1) | $60 | 1 month | $60 |
| GCP (2 nodes for compute) | $0 (credits) | 3 months | $0 |
| WireGuard VPN | $0 | - | $0 |
| **TOTAL (Free Tier)** | **$60/month** | **3 months** | **$180** |
| **TOTAL (After Credits)** | **$120/month** | - | - |

---

### Scenario 2: DigitalOcean + WireGuard VPN + Multi-Cloud Split

| Component | Cost/Month | Duration | Total Cost |
|-----------|-----------|----------|-----------|
| AWS (2 nodes: master + worker-1) | $60 | 1 month | $60 |
| DigitalOcean (2 nodes for compute) | $0 (credits) | 2 months | $0 |
| WireGuard VPN | $0 | - | $0 |
| **TOTAL (Free Tier)** | **$60/month** | **2 months** | **$120** |
| **TOTAL (After Credits)** | **$100/month** | - | - |

---

### Budget-Friendly Option: DO + 1 Node

| Component | Cost/Month | Duration | Total Cost |
|-----------|-----------|----------|-----------|
| AWS (keep all 3 nodes from CA3) | $75 | 1 month | $75 |
| DigitalOcean (1 small node) | $0 (credits) | 2 months | $0 |
| WireGuard VPN | $0 | - | $0 |
| **TOTAL (Free Tier)** | **$75/month** | **2 months** | **$150** |

---

## 🎯 FINAL RECOMMENDATION SUMMARY

If I were doing this assignment, here's what I'd choose:

### Cloud Provider
**DigitalOcean** (Option C)
- Lowest cost ($100/month after credits vs $120-135 for others)
- Simplest setup (less time debugging)
- Still demonstrates multi-cloud patterns
- 2 months free tier (vs 1 month for Azure)

### Topology
**Multi-Cloud Split** (Option A)
- Data tier in AWS (Kafka, MongoDB, Zookeeper)
- Compute tier in DigitalOcean (Producer, Processor)
- Observability in AWS (Prometheus, Grafana, Loki)

### Connectivity
**WireGuard VPN** (Option A)
- $0 cost (vs $72/month for managed VPN)
- Industry standard
- Automatable with Kubernetes manifests

### Component Distribution
**Optimized**:
- AWS: 2 nodes (master + worker-1) = $60/month
- DO: 2 nodes (compute tier) = $40/month (after credits)

### Failure Scenario
**VPN Tunnel Failure** (Option A)
- Best demonstrates multi-cloud aspect
- Clear, testable, recoverable

### Total Cost
- **During free tier**: $60/month (1 month AWS only, then AWS + DO for 1 month on credits)
- **Assignment duration** (1 month): ~$60
- **After credits**: $100/month

---

## ✅ NEXT STEPS (Once Decisions Made)

Once you approve the decisions above, I'll help you:

1. **Terraform for Cloud2** (DigitalOcean/GCP)
   - Create `terraform/cloud2/` directory
   - Configure Kubernetes cluster
   - Set up networking

2. **WireGuard VPN Setup**
   - Generate keys
   - Deploy WireGuard pods in both clusters
   - Configure routing

3. **Deploy Applications to Cloud2**
   - Migrate Producer/Processor manifests
   - Configure to connect to AWS Kafka/MongoDB via VPN
   - Set up Promtail → AWS Loki

4. **Update Observability**
   - Configure Prometheus to scrape Cloud2
   - Update Grafana dashboards for multi-cloud view
   - Test cross-cloud logging

5. **Resilience Testing**
   - Create failure scenario script
   - Document recovery procedure
   - Record demo video

6. **Documentation**
   - Architecture diagram (multi-cloud)
   - Deployment guide
   - Cost analysis
   - Lessons learned

---

## 📝 DECISION TRACKING

| Decision | Status | Chosen Option | Date | Rationale |
|----------|--------|---------------|------|-----------|
| Cloud Provider | 🔴 Pending | - | - | - |
| Topology | 🔴 Pending | - | - | - |
| Connectivity | 🔴 Pending | - | - | - |
| Component Distribution | 🔴 Pending | - | - | - |
| Failure Scenario | 🔴 Pending | - | - | - |

---

**Last Updated**: November 13, 2025
**Status**: Awaiting user input on 5 critical decisions
