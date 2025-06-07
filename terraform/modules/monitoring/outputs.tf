output "dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main.id}?project=${var.project_id}"
}

output "notification_channel" {
  description = "Notification channel for alerts"
  value       = var.notification_email != "" ? google_monitoring_notification_channel.email[0].name : null
}

output "alert_policies" {
  description = "Created alert policies"
  value = {
    api_service_down         = google_monitoring_alert_policy.api_service_down.name
    high_error_rate         = google_monitoring_alert_policy.high_error_rate.name
    database_connection     = google_monitoring_alert_policy.database_connection.name
    high_memory_usage       = google_monitoring_alert_policy.high_memory_usage.name
    firestore_high_operations = google_monitoring_alert_policy.firestore_high_operations.name
  }
}