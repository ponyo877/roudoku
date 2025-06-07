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

variable "notification_email" {
  description = "Email for notifications"
  type        = string
  default     = ""
}

variable "api_service_name" {
  description = "Name of the API Cloud Run service"
  type        = string
}

variable "recommendation_service_name" {
  description = "Name of the recommendation Cloud Run service"
  type        = string
}

variable "database_instance_name" {
  description = "Name of the database instance"
  type        = string
}