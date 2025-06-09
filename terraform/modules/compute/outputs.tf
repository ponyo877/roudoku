output "api_service_url" {
  description = "URL of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.uri
}

output "api_service_name" {
  description = "Name of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.name
}

output "recommendation_service_url" {
  description = "URL of the recommendation endpoints (now integrated in API service)"
  value       = "${google_cloud_run_v2_service.api.uri}/api/v1/users/{user_id}/recommendations"
}

output "recommendation_service_name" {
  description = "Name of the service containing recommendation endpoints"
  value       = google_cloud_run_v2_service.api.name
}

output "etl_job_name" {
  description = "Name of the ETL Cloud Run job"
  value       = google_cloud_run_v2_job.etl.name
}

output "cloud_run_service_account" {
  description = "Service account for Cloud Run services"
  value       = google_service_account.cloud_run_sa.email
}