# Backend configuration for Terraform state
# This should be configured per environment

terraform {
  backend "gcs" {
    bucket = "gke-test-287910-terraform-state"
    prefix = "terraform/state/main"
  }
}

# Note: Before running terraform init, create the GCS bucket for state storage:
# gsutil mb gs://roudoku-terraform-state-dev
# gsutil versioning set on gs://roudoku-terraform-state-dev