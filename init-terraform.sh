#!/bin/bash
# Initialize Terraform for gke-test-287910

set -e

PROJECT_ID="gke-test-287910"
REGION="asia-northeast1"

echo "Initializing Terraform for project: $PROJECT_ID"
echo "==========================================="

# Step 1: Ensure we're authenticated
echo "Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Not authenticated. Please run:"
    echo "  gcloud auth login"
    echo "  gcloud auth application-default login"
    exit 1
fi

# Step 2: Set project
echo "Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Step 3: Check if bucket exists
echo "Checking Terraform state bucket..."
if gsutil ls -b gs://${PROJECT_ID}-terraform-state &>/dev/null; then
    echo "State bucket exists: gs://${PROJECT_ID}-terraform-state"
else
    echo "Creating state bucket..."
    gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-terraform-state
fi

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Step 4: Initialize Terraform with fresh authentication
echo "Refreshing application default credentials..."
gcloud auth application-default login

# Step 5: Initialize Terraform
echo "Initializing Terraform..."
cd terraform

# Remove any existing state
rm -rf .terraform
rm -f .terraform.lock.hcl

# Initialize
terraform init

echo ""
echo "Terraform initialization complete!"
echo ""
echo "Next steps:"
echo "1. Review the plan: terraform plan -var-file=environments/main/terraform.tfvars"
echo "2. Apply changes: terraform apply -var-file=environments/main/terraform.tfvars"