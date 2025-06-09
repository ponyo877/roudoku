# Notification Channel
resource "google_monitoring_notification_channel" "email" {
  count        = var.notification_email != "" ? 1 : 0
  display_name = "Email Notification"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.notification_email
  }

  user_labels = var.labels
}

# Alert Policy for API Service
resource "google_monitoring_alert_policy" "api_service_down" {
  display_name = "API Service Down - ${var.name_suffix}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run service is down"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  user_labels = var.labels
}

# Alert Policy for High Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate - ${var.name_suffix}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Error rate is high"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05 # 5% error rate

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  user_labels = var.labels
}

# Alert Policy for Database Connection Issues
resource "google_monitoring_alert_policy" "database_connection" {
  display_name = "Database Connection Issues - ${var.name_suffix}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Database connection failures"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${var.database_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  user_labels = var.labels
}

# Alert Policy for High Memory Usage
resource "google_monitoring_alert_policy" "high_memory_usage" {
  display_name = "High Memory Usage - ${var.name_suffix}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Memory usage is high"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8 # 80% memory usage

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  user_labels = var.labels
}

# Custom Dashboard
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "Roudoku Application Dashboard - ${var.name_suffix}"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "API Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Requests/second"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 0
          xPos   = 6
          widget = {
            title = "API Error Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Errors/second"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Database Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${var.database_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Connections"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 4
          xPos   = 6
          widget = {
            title = "Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.api_service_name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_INTERPOLATE"
                      crossSeriesReducer = "REDUCE_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Memory Usage %"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 8
          widget = {
            title = "Firestore Operations"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"firestore_instance\" AND metric.type=\"firestore.googleapis.com/document/read_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Operations/second"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# Alert Policy for Firestore High Operation Rate
resource "google_monitoring_alert_policy" "firestore_high_operations" {
  display_name = "Firestore High Operation Rate - ${var.name_suffix}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Firestore operation rate is high"

    condition_threshold {
      filter          = "resource.type=\"firestore_instance\" AND metric.type=\"firestore.googleapis.com/document/read_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1000 # operations per second

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  user_labels = var.labels
}

# Cloud Scheduler Jobs for maintenance tasks
resource "google_cloud_scheduler_job" "etl_daily" {
  name        = "${var.project_id}-etl-daily-${var.name_suffix}"
  description = "Daily ETL job for Aozora Bunko data"
  schedule    = "0 2 * * *" # Daily at 2 AM JST
  time_zone   = "Asia/Tokyo"
  region      = var.region
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.project_id}-etl-${var.name_suffix}:run"

    oauth_token {
      service_account_email = "cloud-run-${var.name_suffix}@${var.project_id}.iam.gserviceaccount.com"
    }
  }

  retry_config {
    retry_count = 3
  }
}

resource "google_cloud_scheduler_job" "ml_training_weekly" {
  name        = "${var.project_id}-ml-training-weekly-${var.name_suffix}"
  description = "Weekly ML model training job"
  schedule    = "0 1 * * 0" # Weekly on Sunday at 1 AM JST
  time_zone   = "Asia/Tokyo"
  region      = var.region
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.project_id}-ml-training-${var.name_suffix}:run"

    oauth_token {
      service_account_email = "cloud-run-${var.name_suffix}@${var.project_id}.iam.gserviceaccount.com"
    }
  }

  retry_config {
    retry_count = 2
  }
}