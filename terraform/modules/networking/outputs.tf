output "vpc_network" {
  description = "The VPC network"
  value       = google_compute_network.vpc
}

output "public_subnet" {
  description = "The public subnet"
  value       = google_compute_subnetwork.public_subnet
}

output "private_subnet" {
  description = "The private subnet"
  value       = google_compute_subnetwork.private_subnet
}

output "vpc_connector" {
  description = "The VPC connector for Cloud Run"
  value       = google_vpc_access_connector.connector
}

output "private_vpc_connection" {
  description = "The private VPC connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection
}