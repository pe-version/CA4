# CA4 GCP Infrastructure - Compute Tier
# Google Kubernetes Engine (GKE) cluster for Producer/Processor workloads

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Provider Configuration
provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "CA4 multi-cloud VPC for GKE compute tier"
}

# Subnet for GKE
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  description = "Subnet for GKE cluster with secondary ranges for pods/services"
}

# Firewall Rules
# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_cidr,
    var.pods_cidr,
    var.services_cidr
  ]

  description = "Allow all internal traffic within VPC and GKE ranges"
}

# Allow WireGuard VPN from AWS
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.vpc_name}-allow-wireguard"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]  # WireGuard default port
  }

  # Will be updated with actual AWS VPN gateway IP after AWS infrastructure is deployed
  source_ranges = ["0.0.0.0/0"]  # TODO: Restrict to AWS VPN gateway IP

  description = "Allow WireGuard VPN traffic from AWS cluster"
}

# Allow SSH for debugging (optional, can be removed for production)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # TODO: Restrict to your IP address
  source_ranges = ["0.0.0.0/0"]

  description = "Allow SSH access for debugging"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.gke_zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Networking mode
  networking_mode = "VPC_NATIVE"

  # Workload Identity (best practice for GKE)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Maintenance window (minimize disruption)
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # 3 AM UTC
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  description = "CA4 compute tier - Producer and Processor workloads"
}

# Separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size_gb
    disk_type    = "pd-standard"

    # OAuth scopes for node access
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels for organization
    labels = {
      environment = "ca4"
      tier        = "compute"
      managed-by  = "terraform"
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Taints for workload isolation (optional)
    # taint {
    #   key    = "workload"
    #   value  = "compute"
    #   effect = "NO_SCHEDULE"
    # }
  }

  # Auto-upgrade and auto-repair
  management {
    auto_repair  = true
    auto_upgrade = true  # Required when using release_channel
  }

  # Autoscaling (optional, can enable later)
  # autoscaling {
  #   min_node_count = 2
  #   max_node_count = 4
  # }
}

# Static IP for WireGuard VPN gateway
resource "google_compute_address" "vpn_gateway" {
  name        = "${var.cluster_name}-vpn-gateway"
  region      = var.gcp_region
  description = "Static IP for WireGuard VPN gateway pod"
}
