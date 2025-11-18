# GCP Configuration for CA4 Multi-Cloud Deployment
# Project: metals-price-tracker
# Region: us-central1 (close to AWS us-east-2 for lower latency)

gcp_project_id      = "metals-price-tracker"
gcp_region          = "us-central1"
gcp_credentials_file = "~/.gcp/metals-price-tracker-terraform-key.json"

# GKE Cluster Configuration
cluster_name        = "ca4-gke-compute"
gke_node_count      = 2
gke_machine_type    = "e2-medium"  # 2 vCPU, 4GB RAM - matches AWS t3.medium
