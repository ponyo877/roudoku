output "firestore_database_name" {
  description = "Firestore database name"
  value       = google_firestore_database.analytics.name
}

output "firestore_location" {
  description = "Firestore database location"
  value       = google_firestore_database.analytics.location_id
}

output "vertex_ai_endpoint" {
  description = "Vertex AI endpoint for recommendations"
  value       = google_vertex_ai_endpoint.recommendation_endpoint.name
}

output "vertex_ai_model" {
  description = "Vertex AI model for recommendations"
  value       = google_vertex_ai_model.recommendation_model.name
}

output "vertex_ai_service_account" {
  description = "Service account for Vertex AI operations"
  value       = google_service_account.vertex_ai_sa.email
}