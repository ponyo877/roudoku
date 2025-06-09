# Reference existing Artifact Registry for Docker images
data "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.artifact_registry_name
}

# Service account for Cloud Build
resource "google_service_account" "cloud_build" {
  account_id   = "roudoku-cloud-build-${var.environment}"
  display_name = "Roudoku Cloud Build Service Account"
  project      = var.project_id
}

# IAM roles for Cloud Build service account
resource "google_project_iam_member" "cloud_build_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Cloud Build trigger for API service
# NOTE: Commented out until GitHub repository is connected via Cloud Console
# Visit https://console.cloud.google.com/cloud-build/triggers/connect to connect repository
#
# resource "google_cloudbuild_trigger" "api_trigger" {
#   name     = "roudoku-api-trigger-${var.environment}"
#   location = var.region
#
#   github {
#     owner = var.github_owner
#     name  = var.github_repo
#     push {
#       branch = var.environment == "prod" ? "^main$" : "^${var.environment}$"
#     }
#   }
#
#   service_account = google_service_account.cloud_build.id
#
#   build {
#     step {
#       name = "gcr.io/cloud-builders/docker"
#       args = [
#         "build",
#         "-t", "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/api:$COMMIT_SHA",
#         "-t", "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/api:latest",
#         "-f", "server/Dockerfile",
#         "server/"
#       ]
#     }
#
#     step {
#       name = "gcr.io/cloud-builders/docker"
#       args = [
#         "push",
#         "--all-tags",
#         "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/api"
#       ]
#     }
#
#     step {
#       name = "gcr.io/google.com/cloudsdktool/cloud-sdk"
#       args = [
#         "run",
#         "deploy",
#         var.api_service_name,
#         "--image", "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/api:$COMMIT_SHA",
#         "--region", var.region,
#         "--platform", "managed",
#         "--allow-unauthenticated"
#       ]
#     }
#
#     options {
#       logging = "CLOUD_LOGGING_ONLY"
#     }
#   }
# }

# Note: Recommendation service trigger removed - functionality is now integrated into the API service
# This eliminates the need for a separate Cloud Build process and deployment

# Cloud Scheduler for ETL jobs
resource "google_cloud_scheduler_job" "etl_scheduler" {
  name             = "roudoku-etl-scheduler-${var.environment}"
  description      = "Monthly Aozora Bunko ETL job"
  schedule         = "0 2 1 * *" # Run at 2 AM on the 1st of each month
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "1800s"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/roudoku-etl-job-${var.environment}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.cloud_build.email
    }
  }
}