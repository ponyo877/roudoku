variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "roudoku"
}

variable "api_service_name" {
  description = "Cloud Run service name for API"
  type        = string
}

variable "recommendation_service_name" {
  description = "Cloud Run service name for recommendation engine (now same as API service)"
  type        = string
}

variable "artifact_registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "roudoku-docker"
}