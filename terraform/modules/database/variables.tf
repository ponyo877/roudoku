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

variable "vpc_network" {
  description = "The VPC network"
  type        = any
}

variable "private_subnet" {
  description = "The private subnet"
  type        = any
}

variable "instance_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}