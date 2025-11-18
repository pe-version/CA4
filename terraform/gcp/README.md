# GCP Terraform - CA4 Compute Tier

This Terraform configuration deploys the **GKE compute tier** for CA4 multi-cloud deployment.

## 🎯 What Gets Deployed

- **GKE Cluster**: 2-node Kubernetes cluster (e2-medium instances)
- **VPC Network**: Dedicated VPC with subnet for GKE
- **Firewall Rules**:
  - Internal VPC communication
  - WireGuard VPN (UDP 51820)
  - SSH access (debugging)
- **Static IP**: For WireGuard VPN gateway

## 📋 Prerequisites

1. **GCP Account Setup**: Follow [../../GCP-SETUP-GUIDE.md](../../GCP-SETUP-GUIDE.md)
2. **Service Account Key**: Downloaded to `~/.gcp/metals-price-tracker-terraform-key.json`
3. **APIs Enabled**:
   - Compute Engine API
   - Kubernetes Engine API
   - IAM API
   - Cloud Resource Manager API
4. **Terraform**: Version 1.5 or later

## 🚀 Deployment

### 1. Verify Configuration

```bash
cd terraform/gcp

# Check terraform.tfvars
cat terraform.tfvars
```

Expected values:
```hcl
gcp_project_id       = "metals-price-tracker"
gcp_region           = "us-central1"
gcp_credentials_file = "~/.gcp/metals-price-tracker-terraform-key.json"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

Expected resources: ~10 resources
- VPC network
- Subnet with secondary ranges
- 4 firewall rules
- GKE cluster
- GKE node pool
- Static IP address

### 4. Deploy Infrastructure

```bash
terraform apply
```

Deployment time: **5-8 minutes**

### 5. Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials ca4-gke-compute \
  --zone=us-central1-a \
  --project=metals-price-tracker

# Verify connection
kubectl get nodes
```

Expected output:
```
NAME                                          STATUS   ROLES    AGE   VERSION
gke-ca4-gke-compute-node-pool-xxxx-xxxx       Ready    <none>   2m    v1.27.x
gke-ca4-gke-compute-node-pool-xxxx-yyyy       Ready    <none>   2m    v1.27.x
```

## 📊 Resource Costs

**GKE Cluster** (2 x e2-medium):
- Instance cost: ~$30/month (2 nodes × 730 hours × $0.0201/hour)
- GKE management: **$0/month** (free tier for 1 cluster)

**Networking**:
- VPC/Subnets: **$0** (free)
- Firewall rules: **$0** (free)
- Static IP (assigned): **$0** (free while in use)

**Total Monthly Cost**: ~$30/month

**With GCP Free Credits**: **$0** for 90 days ($300 credits)

## 🔑 Key Configuration Details

### Networking

| Component | CIDR Range | Purpose |
|-----------|------------|---------|
| Subnet | `10.1.0.0/24` | GKE nodes (256 IPs) |
| Pods | `10.100.0.0/16` | Pod IPs (65,536 IPs) |
| Services | `10.101.0.0/16` | Service IPs (65,536 IPs) |

**AWS Comparison**:
- AWS VPC: `10.0.0.0/16`
- GCP VPC: `10.1.0.0/24` (non-overlapping)

### GKE Cluster

- **Name**: `ca4-gke-compute`
- **Zone**: `us-central1-a`
- **Nodes**: 2
- **Machine Type**: `e2-medium` (2 vCPU, 4GB RAM)
- **Disk**: 50GB per node (standard persistent disk)
- **Networking**: VPC-native (alias IPs)
- **Workload Identity**: Enabled

### Firewall Rules

1. **allow-internal**: All internal VPC traffic
2. **allow-wireguard**: UDP 51820 (VPN tunnel)
3. **allow-ssh**: TCP 22 (debugging, restrict in production)

## 📁 Files

```
terraform/gcp/
├── main.tf              # GKE cluster, VPC, firewall rules
├── variables.tf         # Input variables
├── outputs.tf           # Output values (cluster endpoint, IPs, etc.)
├── terraform.tfvars     # Your GCP credentials (gitignored)
└── README.md            # This file
```

## 🔐 Security Notes

### Service Account Permissions

The `terraform-ca4` service account has:
- **Kubernetes Engine Admin**: Create/manage GKE clusters
- **Compute Admin**: Create/manage VPC, firewall rules
- **Service Account User**: Use service accounts

### Firewall Restrictions

**TODO before production**:
1. Restrict SSH firewall rule to your IP:
   ```hcl
   source_ranges = ["YOUR_IP/32"]
   ```

2. Restrict WireGuard to AWS VPN gateway IP:
   ```hcl
   source_ranges = ["AWS_VPN_GATEWAY_IP/32"]
   ```

### Workload Identity

GKE pods can authenticate to GCP services without service account keys. This is automatically enabled in the cluster configuration.

## 🧹 Cleanup

**Destroy GCP infrastructure**:

```bash
terraform destroy
```

**Cost**: $0 (all resources deleted)

⚠️ **Warning**: This deletes the GKE cluster and all workloads. Back up any data first.

## 🔗 Next Steps

After GCP infrastructure is deployed:

1. ✅ **Verify cluster**: `kubectl get nodes`
2. ⏭️ **Set up WireGuard VPN**: Connect AWS ↔ GCP
3. ⏭️ **Deploy applications**: Producer/Processor to GKE
4. ⏭️ **Configure observability**: Promtail → Loki (AWS)
5. ⏭️ **Test connectivity**: Producer → Kafka (AWS)

## 🆘 Troubleshooting

### Error: "API not enabled"

```
Error: Error creating Network: googleapi: Error 403: Compute Engine API has not been used
```

**Solution**: Enable required APIs:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### Error: "Permission denied"

```
Error: Error reading Cluster: Request had insufficient authentication scopes
```

**Solution**: Verify service account has correct roles:
1. Go to: https://console.cloud.google.com/iam-admin/iam
2. Find `terraform-ca4@metals-price-tracker.iam.gserviceaccount.com`
3. Verify roles: Kubernetes Engine Admin, Compute Admin, Service Account User

### Error: "Credentials file not found"

```
Error: error reading credentials file: open ~/.gcp/metals-price-tracker-terraform-key.json: no such file or directory
```

**Solution**: Download service account key:
1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Click `terraform-ca4` → Keys → Add Key → Create new key (JSON)
3. Save to `~/.gcp/metals-price-tracker-terraform-key.json`

## 📚 Resources

- **GCP Console**: https://console.cloud.google.com
- **GKE Dashboard**: https://console.cloud.google.com/kubernetes/list
- **VPC Networks**: https://console.cloud.google.com/networking/networks/list
- **Terraform Google Provider**: https://registry.terraform.io/providers/hashicorp/google/latest/docs

---

**Last Updated**: November 17, 2025
**Status**: Ready for deployment
