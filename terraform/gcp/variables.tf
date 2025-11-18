# GCP Variables for CA4 Multi-Cloud Deployment

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_credentials_file" {
  description = "Path to GCP service account JSON key file"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "ca4-gke-compute"
}

variable "gke_node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 2
}

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-medium"  # 2 vCPU, 4GB RAM
}

variable "gke_disk_size_gb" {
  description = "Boot disk size for GKE nodes (GB)"
  type        = number
  default     = 50
}

variable "gke_zone" {
  description = "GKE cluster zone (within region)"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "ca4-gcp-vpc"
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
  default     = "10.1.0.0/24"  # Different from AWS 10.0.x.x
}

variable "pods_cidr" {
  description = "Secondary IP range for pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "services_cidr" {
  description = "Secondary IP range for services"
  type        = string
  default     = "10.101.0.0/16"
}
