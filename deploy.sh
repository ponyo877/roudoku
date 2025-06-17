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

# Step 12: Build and deploy API server
echo "Building and deploying API server..."
cd server

# Build new Docker image with timestamp tag
IMAGE_TAG=$(date +%s)
echo "Building image with tag: $IMAGE_TAG"

gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/roudoku-docker/api:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "Docker build successful. Deploying to Cloud Run..."
    
    # Deploy to Cloud Run with the new image
    gcloud run deploy roudoku-api \
        --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/roudoku-docker/api:${IMAGE_TAG} \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --set-env-vars=PROJECT_ID=${PROJECT_ID},DB_HOST=35.221.91.3,DB_NAME=roudoku,DB_USER=roudoku_app,DB_PASSWORD=roudoku2024,DB_SSLMODE=require \
        --set-cloudsql-instances=gke-test-287910:asia-northeast1:gke-test-287910-postgres-main-09l5cj \
        --max-instances=10 \
        --min-instances=1 \
        --cpu=1 \
        --memory=1Gi \
        --port=8080 \
        --timeout=300
    
    if [ $? -eq 0 ]; then
        echo "API deployment successful!"
        
        # Test the TTS endpoint
        echo "Testing TTS endpoint..."
        sleep 10  # Wait for service to be ready
        
        TTS_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
            https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/tts/synthesize \
            -H "Content-Type: application/json" \
            -d '{"text":"テスト音声です"}' \
            --max-time 10)
        
        HTTP_CODE=$(echo "$TTS_RESPONSE" | tail -c 4)
        
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ TTS endpoint is working correctly!"
        else
            echo "⚠️  TTS endpoint returned HTTP $HTTP_CODE"
            echo "Response: $TTS_RESPONSE"
        fi
        
        # Test health endpoint
        echo "Testing health endpoint..."
        HEALTH_RESPONSE=$(curl -s https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/health)
        echo "Health check response: $HEALTH_RESPONSE"
        
    else
        echo "❌ API deployment failed!"
        exit 1
    fi
else
    echo "❌ Docker build failed!"
    exit 1
fi

cd ..

echo ""
echo "Deployment complete!"
echo "==================="
echo ""
echo "Services deployed:"
echo "- API Server: https://roudoku-api-1083612487436.asia-northeast1.run.app"
echo "- TTS Endpoint: https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/tts/synthesize"
echo ""
echo "Next steps:"
echo "1. Run database migrations: ./scripts/setup-database.sh"
echo "2. Configure Firebase Authentication in the console"
echo "3. Update mobile app configuration files"
echo ""
echo "Useful commands:"
echo "- Check Cloud Run services: gcloud run services list --region=$REGION"
echo "- View Cloud SQL instances: gcloud sql instances list"
echo "- Check Cloud Build history: gcloud builds list --limit=5"