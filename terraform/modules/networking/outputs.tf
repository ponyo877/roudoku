output "vpc_network" {
  description = "The VPC network"
  value       = length(google_compute_network.vpc) > 0 ? google_compute_network.vpc[0] : null
}

output "private_subnet" {
  description = "The private subnet"
  value       = length(google_compute_subnetwork.private_subnet) > 0 ? google_compute_subnetwork.private_subnet[0] : null
}

output "vpc_connector" {
  description = "The VPC connector for Cloud Run (deprecated)"
  value       = null
}

output "private_vpc_connection" {
  description = "The private VPC connection for Cloud SQL"
  value       = length(google_service_networking_connection.private_vpc_connection) > 0 ? google_service_networking_connection.private_vpc_connection[0] : null
}