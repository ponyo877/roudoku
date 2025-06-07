# Development Environment Configuration

# Project Configuration
project_id  = "roudoku-dev-123456" # Replace with your actual project ID
region      = "asia-northeast1"
zone        = "asia-northeast1-a"
environment = "dev"

# Application Configuration
app_name    = "roudoku"
app_version = "v1.0.0-dev"

# Database Configuration (Smaller instance for dev)
db_instance_tier   = "db-f1-micro"
db_disk_size       = 10
db_backup_enabled  = false

# Cloud Run Configuration (Minimal resources for dev)
cloud_run_min_instances = 0
cloud_run_max_instances = 3
cloud_run_cpu          = "1"
cloud_run_memory       = "512Mi"

# Storage Configuration
storage_location = "ASIA-NORTHEAST1"

# AI/ML Configuration
vertex_ai_region = "asia-northeast1"

# Monitoring Configuration
notification_email = "dev-team@example.com" # Replace with actual email

# Labels
labels = {
  application = "roudoku"
  environment = "dev"
  managed-by  = "terraform"
  team        = "development"
}