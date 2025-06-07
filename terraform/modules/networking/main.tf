# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc-${var.name_suffix}"
  auto_create_subnetworks = false
  mtu                     = 1460
  
  project = var.project_id
}

# Public Subnet for Cloud Run
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_id}-public-${var.name_suffix}"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  project = var.project_id
}

# Private Subnet for Database
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_id}-private-${var.name_suffix}"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
  
  project = var.project_id
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router-${var.name_suffix}"
  region  = var.region
  network = google_compute_network.vpc.id
  
  project = var.project_id
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat-${var.name_suffix}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  project = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# VPC Connector for Cloud Run to VPC access
resource "google_vpc_access_connector" "connector" {
  name          = "${var.project_id}-connector-${var.name_suffix}"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name
  
  project = var.project_id
  
  min_instances = 2
  max_instances = 3
  
  machine_type = "e2-micro"
}

# Private Service Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_id}-private-ip-${var.name_suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  
  project = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_id}-allow-internal-${var.name_suffix}"
  network = google_compute_network.vpc.name
  project = var.project_id

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

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["internal"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.project_id}-allow-health-check-${var.name_suffix}"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["cloud-run"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_id}-allow-ssh-${var.name_suffix}"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}