# Service Account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-${var.name_suffix}"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run services"
  project      = var.project_id
}

# IAM roles for Cloud Run service account
resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_cloud_tasks_enqueuer" {
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Unified API Cloud Run Service (includes recommendations)
resource "google_cloud_run_v2_service" "api" {
  name     = "${var.project_id}-api-${var.name_suffix}"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cloud_run_sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Conditional VPC access - only if VPC connector exists
    dynamic "vpc_access" {
      for_each = var.vpc_connector != null ? [1] : []
      content {
        connector = var.vpc_connector.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = true
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "DATABASE_CONNECTION"
        value = var.database_connection
      }

      env {
        name  = "ENVIRONMENT"
        value = "production"
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "REGION"
        value = var.region
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 60
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    labels = var.labels
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  labels = var.labels
}

# Note: Recommendation service is now integrated into the unified API service above
# This eliminates the need for a separate Cloud Run instance, saving costs

# ETL Cloud Run Job for data processing
resource "google_cloud_run_v2_job" "etl" {
  name     = "${var.project_id}-etl-${var.name_suffix}"
  location = var.region
  project  = var.project_id

  template {
    task_count  = 1
    parallelism = 1
    
    template {
      service_account = google_service_account.cloud_run_sa.email
      timeout = "3600s" # 1 hour

      # Conditional VPC access - only if VPC connector exists
      dynamic "vpc_access" {
        for_each = var.vpc_connector != null ? [1] : []
        content {
          connector = var.vpc_connector.id
          egress    = "PRIVATE_RANGES_ONLY"
        }
      }

      containers {
        image = "gcr.io/cloudrun/hello" # Placeholder image

        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }

        env {
          name  = "DATABASE_CONNECTION"
          value = var.database_connection
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "REGION"
          value = var.region
        }
      }
    }

    labels = var.labels
  }

  labels = var.labels
}

# IAM Policy for public access to API service
resource "google_cloud_run_service_iam_member" "api_public" {
  location = google_cloud_run_v2_service.api.location
  project  = google_cloud_run_v2_service.api.project
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Note: No separate recommendation service IAM needed since it's integrated into the API service