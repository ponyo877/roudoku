#!/bin/bash
# Aozora StoryWalk GCP Setup Script

set -e

# Configuration
PROJECT_ID="gke-test-287910"
REGION="asia-northeast1"
ZONE="asia-northeast1-a"

echo "Setting up Aozora StoryWalk GCP Project..."

# Create project (if not exists)
if ! gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo "Creating project $PROJECT_ID..."
    gcloud projects create $PROJECT_ID --name="Aozora StoryWalk"
else
    echo "Project $PROJECT_ID already exists"
fi

# Set current project
gcloud config set project $PROJECT_ID

# Enable billing (manual step required)
echo "Please ensure billing is enabled for project $PROJECT_ID"
echo "Visit: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
read -p "Press enter when billing is enabled..."

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable \
    cloudsql.googleapis.com \
    firestore.googleapis.com \
    texttospeech.googleapis.com \
    firebase.googleapis.com \
    storage.googleapis.com \
    run.googleapis.com \
    aiplatform.googleapis.com \
    pubsub.googleapis.com \
    cloudtasks.googleapis.com \
    secretmanager.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    cloudscheduler.googleapis.com \
    compute.googleapis.com \
    vpcaccess.googleapis.com

# Create Artifact Registry for Docker images
echo "Creating Artifact Registry..."
gcloud artifacts repositories create roudoku-docker \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker images for Aozora StoryWalk"

# Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Create service accounts
echo "Creating service accounts..."

# API service account
gcloud iam service-accounts create roudoku-api \
    --display-name="Roudoku API Service"

# ETL service account
gcloud iam service-accounts create roudoku-etl \
    --display-name="Roudoku ETL Service"

# CI/CD service account
gcloud iam service-accounts create roudoku-cicd \
    --display-name="Roudoku CI/CD Service"

# Set up Firebase
echo "Setting up Firebase..."
firebase projects:addfirebase $PROJECT_ID || echo "Firebase may already be added"

# Create Firestore database
echo "Creating Firestore database..."
gcloud firestore databases create \
    --location=$REGION \
    --type=firestore-native || echo "Firestore database may already exist"

# Create Cloud Storage buckets for Terraform state
echo "Creating Terraform state bucket..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-terraform-state || echo "Bucket may already exist"
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Set default region and zone
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "GCP setup complete!"
echo ""
echo "Next steps:"
echo "1. Initialize Terraform: cd terraform && terraform init"
echo "2. Configure Firebase Authentication in the console"
echo "3. Set up environment variables in terraform/environments/main/terraform.tfvars"
echo "4. Run Terraform plan: terraform plan -var-file=environments/main/terraform.tfvars"