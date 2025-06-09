#!/bin/bash
# Enable APIs for gke-test-287910

set -e

PROJECT_ID="gke-test-287910"

echo "Enabling APIs for project: $PROJECT_ID"
echo "======================================"

# Set project
gcloud config set project $PROJECT_ID

# Enable APIs one by one to catch any issues
APIS=(
    "run.googleapis.com"
    "sqladmin.googleapis.com" 
    "storage.googleapis.com"
    "pubsub.googleapis.com"
    "firestore.googleapis.com"
    "aiplatform.googleapis.com"
    "texttospeech.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudscheduler.googleapis.com"
    "cloudtasks.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "vpcaccess.googleapis.com"
    "servicenetworking.googleapis.com"
    "artifactregistry.googleapis.com"
    "compute.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    if gcloud services enable "$api" --project="$PROJECT_ID"; then
        echo "✓ $api enabled successfully"
    else
        echo "✗ Failed to enable $api"
        echo "This might be due to billing not being enabled or API not available in this region"
    fi
done

echo ""
echo "API enablement complete!"
echo ""
echo "Now you can run: terraform apply tfplan"