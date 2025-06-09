# Simplified VPC Network (conditional creation)
resource "google_compute_network" "vpc" {
  count                   = var.enable_vpc ? 1 : 0
  name                    = "${var.project_id}-vpc-${var.name_suffix}"
  auto_create_subnetworks = false
  mtu                     = 1460
  
  project = var.project_id
}

# Private Subnet (only if VPC is enabled)
resource "google_compute_subnetwork" "private_subnet" {
  count         = var.enable_vpc ? 1 : 0
  name          = "${var.project_id}-private-${var.name_suffix}"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc[0].id
  
  private_ip_google_access = true
  
  project = var.project_id
}

# Global address for private service connection (only if VPC is enabled)
resource "google_compute_global_address" "private_ip_address" {
  count          = var.enable_vpc ? 1 : 0
  name           = "${var.project_id}-private-ip-${var.name_suffix}"
  purpose        = "VPC_PEERING"
  address_type   = "INTERNAL"
  prefix_length  = 16
  network        = google_compute_network.vpc[0].id
  
  project = var.project_id
}

# Private service connection (only if VPC is enabled)
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_vpc ? 1 : 0
  network                 = google_compute_network.vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

# Basic firewall rules (only if VPC is enabled)
resource "google_compute_firewall" "allow_internal" {
  count     = var.enable_vpc ? 1 : 0
  name      = "${var.project_id}-allow-internal-${var.name_suffix}"
  network   = google_compute_network.vpc[0].name
  direction = "INGRESS"
  
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
  
  source_ranges = ["10.0.0.0/16"]
  
  project = var.project_id
}