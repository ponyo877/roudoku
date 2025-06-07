# Backend configuration for Terraform state
# This should be configured per environment

terraform {
  backend "gcs" {
    # bucket = "your-terraform-state-bucket"
    # prefix = "terraform/state"
    
    # Uncomment and configure for each environment:
    # bucket = "roudoku-terraform-state-dev"    # for dev
    # bucket = "roudoku-terraform-state-prod"   # for prod
    # prefix = "terraform/state"
  }
}

# Note: Before running terraform init, create the GCS bucket for state storage:
# gsutil mb gs://roudoku-terraform-state-dev
# gsutil versioning set on gs://roudoku-terraform-state-dev