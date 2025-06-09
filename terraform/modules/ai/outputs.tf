output "firestore_database_name" {
  description = "Firestore database name"
  value       = google_firestore_database.analytics.name
}

output "firestore_location" {
  description = "Firestore database location"
  value       = google_firestore_database.analytics.location_id
}

output "vertex_ai_region" {
  description = "Vertex AI region for deployments"
  value       = var.vertex_ai_region
}

output "vertex_ai_service_account" {
  description = "Service account for Vertex AI operations"
  value       = google_service_account.vertex_ai_sa.email
}