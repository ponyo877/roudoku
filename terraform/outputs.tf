# Project Information
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

# Database Outputs
output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = module.database.connection_name
  sensitive   = true
}

output "database_private_ip" {
  description = "Cloud SQL instance private IP"
  value       = module.database.private_ip
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

# Cloud Run Outputs
output "api_service_url" {
  description = "URL of the API Cloud Run service"
  value       = module.compute.api_service_url
}

output "recommendation_service_url" {
  description = "URL of the recommendation Cloud Run service"
  value       = module.compute.recommendation_service_url
}

# Storage Outputs
output "content_bucket_name" {
  description = "Name of the content storage bucket"
  value       = module.storage.content_bucket_name
}

output "audio_bucket_name" {
  description = "Name of the audio storage bucket"
  value       = module.storage.audio_bucket_name
}

output "backup_bucket_name" {
  description = "Name of the backup storage bucket"
  value       = module.storage.backup_bucket_name
}

# Pub/Sub Outputs
output "pubsub_topics" {
  description = "Created Pub/Sub topics"
  value       = module.storage.pubsub_topics
}

# Firestore Outputs
output "firestore_database_name" {
  description = "Firestore database name for analytics"
  value       = module.ai.firestore_database_name
}

output "firestore_location" {
  description = "Firestore database location"
  value       = module.ai.firestore_location
}

# Vertex AI Outputs
output "vertex_ai_region" {
  description = "Vertex AI region for deployments"
  value       = module.ai.vertex_ai_region
}

# Monitoring Outputs
output "monitoring_dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = module.monitoring.dashboard_url
}