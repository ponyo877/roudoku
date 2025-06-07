# Production Environment Configuration

# Project Configuration
project_id  = "roudoku-prod-123456" # Replace with your actual project ID
region      = "asia-northeast1"
zone        = "asia-northeast1-a"
environment = "prod"

# Application Configuration
app_name    = "roudoku"
app_version = "v1.0.0"

# Database Configuration (Production-grade instance)
db_instance_tier   = "db-custom-2-4096" # 2 vCPUs, 4GB RAM
db_disk_size       = 100
db_backup_enabled  = true

# Cloud Run Configuration (Production resources)
cloud_run_min_instances = 2
cloud_run_max_instances = 100
cloud_run_cpu          = "2"
cloud_run_memory       = "2Gi"

# Storage Configuration
storage_location = "ASIA-NORTHEAST1"

# AI/ML Configuration
vertex_ai_region = "asia-northeast1"

# Monitoring Configuration
notification_email = "alerts@example.com" # Replace with actual email

# Labels
labels = {
  application = "roudoku"
  environment = "prod"
  managed-by  = "terraform"
  team        = "production"
}