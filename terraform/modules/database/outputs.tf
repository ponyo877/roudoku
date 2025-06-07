output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.app_db.name
}

output "username" {
  description = "The database username"
  value       = google_sql_user.app_user.name
  sensitive   = true
}

output "password_secret_name" {
  description = "The name of the secret containing the database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "connection_secret_name" {
  description = "The name of the secret containing the database connection string"
  value       = google_secret_manager_secret.db_connection_string.secret_id
}