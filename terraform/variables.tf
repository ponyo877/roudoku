# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Application Configuration
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "roudoku"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "v1.0.0"
}

# Database Configuration
variable "db_instance_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "db_backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Cloud Run Configuration
variable "cloud_run_min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
}

variable "cloud_run_max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run"
  type        = string
  default     = "512Mi"
}

# Storage Configuration
variable "storage_location" {
  description = "Cloud Storage bucket location"
  type        = string
  default     = "ASIA-NORTHEAST1"
}

# AI/ML Configuration
variable "vertex_ai_region" {
  description = "Vertex AI region"
  type        = string
  default     = "asia-northeast1"
}

# Monitoring Configuration
variable "notification_email" {
  description = "Email for notifications"
  type        = string
  default     = ""
}

# Tags
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    application = "roudoku"
    managed-by  = "terraform"
  }
}