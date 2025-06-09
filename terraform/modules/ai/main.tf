# Cloud Firestore Database
resource "google_firestore_database" "analytics" {
  project                     = var.project_id
  name                       = "analytics"
  location_id                = var.region
  type                       = "FIRESTORE_NATIVE"
  concurrency_mode           = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"

  # Enable point-in-time recovery
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
  
  # Enable delete protection
  delete_protection_state = "DELETE_PROTECTION_ENABLED"

  depends_on = [
    google_project_service.firestore
  ]
}

# Enable Firestore API
resource "google_project_service" "firestore" {
  project = var.project_id
  service = "firestore.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy        = false
}

# Note: Vertex AI models and endpoints are typically deployed via the API
# or gcloud commands after training. We'll prepare the infrastructure here.

# Service account for AI workloads
resource "google_project_iam_member" "vertex_ai_custom_code" {
  project = var.project_id
  role    = "roles/aiplatform.customCodeServiceAgent"
  member  = "serviceAccount:${google_service_account.vertex_ai_sa.email}"
}

# Service Account for Vertex AI
resource "google_service_account" "vertex_ai_sa" {
  account_id   = "vertex-ai-${var.name_suffix}"
  display_name = "Vertex AI Service Account"
  description  = "Service account for Vertex AI operations"
  project      = var.project_id
}

# IAM roles for Vertex AI service account
resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vertex_ai_sa.email}"
}

resource "google_project_iam_member" "vertex_ai_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.vertex_ai_sa.email}"
}

resource "google_project_iam_member" "vertex_ai_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.vertex_ai_sa.email}"
}