variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_connector" {
  description = "The VPC connector for Cloud Run (can be null if VPC is disabled)"
  type        = any
  default     = null
}

variable "database_connection" {
  description = "Database connection name"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "cpu" {
  description = "CPU allocation for Cloud Run"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for Cloud Run"
  type        = string
  default     = "512Mi"
}