#!/bin/bash
# Deployment script for Aozora StoryWalk to gke-test-287910

set -e

PROJECT_ID="gke-test-287910"
REGION="asia-northeast1"

echo "Deploying Aozora StoryWalk to project: $PROJECT_ID"
echo "============================================"

# Step 1: Set current project
echo "Setting current project..."
gcloud config set project $PROJECT_ID

# Step 2: Check if we're authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Please authenticate with Google Cloud:"
    gcloud auth login
fi

# Verify the project is set correctly
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "Error: Project not set correctly. Current: $CURRENT_PROJECT, Expected: $PROJECT_ID"
    exit 1
fi

echo "Using project: $CURRENT_PROJECT"

# Step 3: Enable APIs
echo "Enabling required APIs..."
# gcloud services enable \
#     cloudsql.googleapis.com \
#     firestore.googleapis.com \
#     texttospeech.googleapis.com \
#     firebase.googleapis.com \
#     storage.googleapis.com \
#     run.googleapis.com \
#     aiplatform.googleapis.com \
#     pubsub.googleapis.com \
#     cloudtasks.googleapis.com \
#     secretmanager.googleapis.com \
#     cloudbuild.googleapis.com \
#     artifactregistry.googleapis.com \
#     cloudscheduler.googleapis.com \
#     compute.googleapis.com \
#     vpcaccess.googleapis.com \
#     servicenetworking.googleapis.com

# Step 4: Create Terraform state bucket
echo "Creating Terraform state bucket..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-terraform-state || echo "Bucket may already exist"
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Step 4.5: Re-authenticate for application default credentials
echo "Re-authenticating for Terraform..."
gcloud auth application-default login

# Step 5: Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init -reconfigure

# Step 6: Plan Terraform changes
echo "Planning Terraform changes..."
terraform plan -var-file=environments/main/terraform.tfvars -out=tfplan

# Step 7: Apply Terraform (with confirmation)
echo ""
echo "Ready to apply Terraform changes."
read -p "Do you want to continue? (yes/no): " confirm
if [[ $confirm == "yes" ]]; then
    terraform apply tfplan
else
    echo "Terraform apply cancelled."
    exit 1
fi

# Step 8: Create Artifact Registry
echo "Creating Artifact Registry..."
gcloud artifacts repositories create roudoku-docker \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker images for Aozora StoryWalk" || echo "Repository may already exist"

# Step 9: Configure Docker authentication
echo "Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Step 10: Set up Firebase
echo "Setting up Firebase..."
cd ..
firebase projects:addfirebase $PROJECT_ID || echo "Firebase may already be added"

# Step 11: Create Firestore indexes (if needed)
echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules --project $PROJECT_ID || echo "Firestore rules deployment skipped"

echo ""
echo "Deployment complete!"
echo "==================="
echo ""
echo "Next steps:"
echo "1. Run database migrations: ./scripts/setup-database.sh"
echo "2. Configure Firebase Authentication in the console"
echo "3. Update mobile app configuration files"
echo "4. Deploy the API: gcloud builds submit --config cloudbuild.yaml"
echo ""
echo "Useful commands:"
echo "- Check Cloud Run services: gcloud run services list --region=$REGION"
echo "- View Cloud SQL instances: gcloud sql instances list"
echo "- Check Cloud Build history: gcloud builds list --limit=5"