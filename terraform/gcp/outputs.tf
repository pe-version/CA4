# GCP Terraform Outputs

output "gcp_project_id" {
  description = "GCP Project ID"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP Region"
  value       = var.gcp_region
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "pods_cidr" {
  description = "Pods secondary IP range"
  value       = var.pods_cidr
}

output "services_cidr" {
  description = "Services secondary IP range"
  value       = var.services_cidr
}

output "vpn_gateway_ip" {
  description = "Static IP for WireGuard VPN gateway"
  value       = google_compute_address.vpn_gateway.address
}

output "node_pool_name" {
  description = "GKE node pool name"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_count" {
  description = "Number of GKE nodes"
  value       = google_container_node_pool.primary_nodes.node_count
}

output "machine_type" {
  description = "GKE node machine type"
  value       = var.gke_machine_type
}

# Kubectl configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone=${var.gke_zone} --project=${var.gcp_project_id}"
}

# Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project           = var.gcp_project_id
    region            = var.gcp_region
    cluster_name      = google_container_cluster.primary.name
    cluster_zone      = var.gke_zone
    node_count        = var.gke_node_count
    machine_type      = var.gke_machine_type
    vpc_network       = google_compute_network.vpc.name
    subnet_cidr       = var.subnet_cidr
    vpn_gateway_ip    = google_compute_address.vpn_gateway.address
    kubectl_context   = "gke_${var.gcp_project_id}_${var.gke_zone}_${google_container_cluster.primary.name}"
  }
}
