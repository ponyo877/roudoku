# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Cloud SQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = "${var.project_id}-postgres-${var.name_suffix}"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  deletion_protection = false

  settings {
    tier = var.instance_tier
    
    disk_type       = "PD_SSD"
    disk_size       = var.disk_size
    disk_autoresize = true
    
    availability_type = "REGIONAL"
    
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                    = "02:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
      transaction_log_retention_days = 7
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_network.id
      enable_private_path_for_google_cloud_services = true
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }

    database_flags {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    user_labels = var.labels
  }

  depends_on = [var.private_subnet]
}

# Main application database
resource "google_sql_database" "app_db" {
  name     = "roudoku"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# Database user
resource "google_sql_user" "app_user" {
  name     = "roudoku_app"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
  project  = var.project_id
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_id}-db-password-${var.name_suffix}"
  project   = var.project_id

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_connection_string" {
  secret_id = "${var.project_id}-db-connection-${var.name_suffix}"
  project   = var.project_id

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_connection_string" {
  secret = google_secret_manager_secret.db_connection_string.id
  secret_data = jsonencode({
    host     = google_sql_database_instance.postgres.private_ip_address
    port     = "5432"
    database = google_sql_database.app_db.name
    username = google_sql_user.app_user.name
    password = random_password.db_password.result
    sslmode  = "require"
  })
}