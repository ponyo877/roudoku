# Deployment Guide for gke-test-287910

This guide will help you deploy the Aozora StoryWalk infrastructure to your GCP project `gke-test-287910`.

## Prerequisites

1. Install required tools:
   ```bash
   # Google Cloud SDK
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   
   # Terraform
   brew install terraform
   
   # Firebase CLI
   npm install -g firebase-tools
   
   # Cloud SQL Proxy (for database setup)
   curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
   chmod +x cloud_sql_proxy
   ```

2. Authenticate:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   firebase login
   ```

## Step-by-Step Deployment

### 1. Set Project and Enable APIs

```bash
# Set current project
gcloud config set project gke-test-287910

# Enable required APIs
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
    vpcaccess.googleapis.com \
    servicenetworking.googleapis.com
```

### 2. Create Terraform State Bucket

```bash
# Create bucket for Terraform state
gsutil mb -p gke-test-287910 -c STANDARD -l asia-northeast1 gs://gke-test-287910-terraform-state

# Enable versioning
gsutil versioning set on gs://gke-test-287910-terraform-state
```

### 3. Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init -reconfigure

# Review the plan
terraform plan -var-file=environments/main/terraform.tfvars

# Apply the configuration
terraform apply -var-file=environments/main/terraform.tfvars
```

**Note**: Terraform will create:
- VPC network and subnets
- Cloud SQL PostgreSQL instance
- Cloud Storage buckets
- Cloud Run services
- Pub/Sub topics
- Service accounts
- Firestore database

### 4. Create Artifact Registry

```bash
# Create Docker repository
gcloud artifacts repositories create roudoku-docker \
    --repository-format=docker \
    --location=asia-northeast1 \
    --description="Docker images for Aozora StoryWalk"

# Configure Docker authentication
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

### 5. Set up Firebase

```bash
# Add Firebase to the project
firebase projects:addfirebase gke-test-287910

# Deploy Firestore rules (from project root)
cd ..
firebase deploy --only firestore:rules --project gke-test-287910
```

### 6. Configure Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project `gke-test-287910`
3. Navigate to Authentication > Sign-in method
4. Enable:
   - Email/Password
   - Google Sign-In

### 7. Run Database Migrations

After Terraform completes:

```bash
cd scripts
./setup-database.sh
```

This will:
- Connect to the Cloud SQL instance
- Run database migrations
- Install pgvector extension

### 8. Deploy the API Service

```bash
# From project root
gcloud builds submit --config cloudbuild.yaml \
    --substitutions=_REGION=asia-northeast1,_SERVICE_NAME=roudoku-api-dev
```

## Verification Steps

1. **Check Infrastructure**:
   ```bash
   # Cloud SQL
   gcloud sql instances list
   
   # Cloud Run services
   gcloud run services list --region=asia-northeast1
   
   # Storage buckets
   gsutil ls
   
   # Firestore
   gcloud firestore databases list
   ```

2. **Test API Endpoint**:
   ```bash
   # Get the service URL
   SERVICE_URL=$(gcloud run services describe roudoku-api-dev \
       --region=asia-northeast1 \
       --format='value(status.url)')
   
   # Test health endpoint
   curl $SERVICE_URL/health
   ```

## Important URLs and Resources

- **Cloud Console**: https://console.cloud.google.com/home/dashboard?project=gke-test-287910
- **Firebase Console**: https://console.firebase.google.com/project/gke-test-287910
- **Cloud Run Services**: https://console.cloud.google.com/run?project=gke-test-287910
- **Cloud SQL**: https://console.cloud.google.com/sql/instances?project=gke-test-287910

## Troubleshooting

### API Not Enabled Error
If you get "API not enabled" errors, run:
```bash
gcloud services list --enabled
```
And enable any missing APIs from the list above.

### Terraform State Lock
If Terraform state is locked:
```bash
terraform force-unlock <LOCK_ID>
```

### Database Connection Issues
1. Ensure Cloud SQL Admin API is enabled
2. Check that the service account has the necessary permissions
3. Verify the VPC connector is created

### Firebase Issues
1. Ensure you're logged in: `firebase login`
2. Check project association: `firebase projects:list`
3. Verify Firestore is in Native mode (not Datastore mode)

## Next Steps

After successful deployment:
1. Configure the mobile app with Firebase credentials
2. Set up CI/CD triggers in Cloud Build
3. Configure monitoring alerts
4. Test the recommendation engine
5. Begin Phase 2 implementation

## Cost Monitoring

Monitor costs at: https://console.cloud.google.com/billing/projects/gke-test-287910

Estimated monthly costs for development:
- Cloud SQL (db-f1-micro): ~$15
- Cloud Run (minimal traffic): ~$5
- Storage & Firestore: ~$2
- Total: ~$22/month