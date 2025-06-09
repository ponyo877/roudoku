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

variable "enable_vpc" {
  description = "Enable VPC creation"
  type        = bool
  default     = true
}