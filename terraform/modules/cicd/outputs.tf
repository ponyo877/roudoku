output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.docker.repository_id}"
}

output "cloud_build_service_account" {
  description = "Email of the Cloud Build service account"
  value       = google_service_account.cloud_build.email
}

# output "api_trigger_id" {
#   description = "ID of the API Cloud Build trigger"
#   value       = google_cloudbuild_trigger.api_trigger.id
# }
#
# output "recommendation_trigger_id" {
#   description = "ID of the Recommendation Cloud Build trigger (now integrated with API)"
#   value       = google_cloudbuild_trigger.api_trigger.id
# }