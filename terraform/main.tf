# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudrun.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "firestore.googleapis.com",
    "aiplatform.googleapis.com",
    "texttospeech.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Local values
locals {
  name_suffix = "${var.environment}-${random_string.suffix.result}"
  common_labels = merge(var.labels, {
    environment = var.environment
  })
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_id    = var.project_id
  region        = var.region
  name_suffix   = local.name_suffix
  labels        = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# Database Module
module "database" {
  source = "./modules/database"

  project_id          = var.project_id
  region              = var.region
  name_suffix         = local.name_suffix
  labels              = local.common_labels
  
  vpc_network         = module.networking.vpc_network
  private_subnet      = module.networking.private_subnet
  
  instance_tier       = var.db_instance_tier
  disk_size           = var.db_disk_size
  backup_enabled      = var.db_backup_enabled

  depends_on = [module.networking]
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  project_id      = var.project_id
  region          = var.region
  name_suffix     = local.name_suffix
  labels          = local.common_labels
  
  storage_location = var.storage_location

  depends_on = [google_project_service.required_apis]
}

# AI Module (BigQuery, Vertex AI)
module "ai" {
  source = "./modules/ai"

  project_id         = var.project_id
  region             = var.region
  vertex_ai_region   = var.vertex_ai_region
  name_suffix        = local.name_suffix
  labels             = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# Compute Module (Cloud Run)
module "compute" {
  source = "./modules/compute"

  project_id           = var.project_id
  region               = var.region
  name_suffix          = local.name_suffix
  labels               = local.common_labels
  
  vpc_connector        = module.networking.vpc_connector
  database_connection  = module.database.connection_name
  
  min_instances        = var.cloud_run_min_instances
  max_instances        = var.cloud_run_max_instances
  cpu                  = var.cloud_run_cpu
  memory               = var.cloud_run_memory

  depends_on = [module.networking, module.database]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  project_id         = var.project_id
  region             = var.region
  name_suffix        = local.name_suffix
  labels             = local.common_labels
  
  notification_email = var.notification_email
  
  # Services to monitor
  api_service_name           = module.compute.api_service_name
  recommendation_service_name = module.compute.recommendation_service_name
  database_instance_name     = module.database.instance_name

  depends_on = [module.compute, module.database]
}