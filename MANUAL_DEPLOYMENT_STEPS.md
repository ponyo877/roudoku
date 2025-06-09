# Manual Deployment Steps for gke-test-287910

Since you're encountering authentication issues, here are the manual steps to deploy:

## Step 1: Fix Authentication

Run these commands in your terminal:

```bash
# Clear existing credentials
gcloud auth revoke --all
rm -rf ~/.config/gcloud/application_default_credentials.json

# Re-authenticate
gcloud auth login
gcloud config set project gke-test-287910
gcloud auth application-default login
```

## Step 2: Verify Access

```bash
# Test that you can access the project
gcloud projects describe gke-test-287910

# Test bucket access
gsutil ls gs://gke-test-287910-terraform-state/
```

## Step 3: Initialize Terraform

```bash
cd terraform

# Clean up any existing state
rm -rf .terraform
rm -f .terraform.lock.hcl

# Initialize Terraform
terraform init
```

If you still get authentication errors, try:

```bash
# Use explicit credentials
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
terraform init
```

## Step 4: Deploy Infrastructure

```bash
# Plan the deployment
terraform plan -var-file=environments/main/terraform.tfvars

# Apply if everything looks good
terraform apply -var-file=environments/main/terraform.tfvars
```

## Step 5: Create Artifact Registry (if Terraform didn't create it)

```bash
gcloud artifacts repositories create roudoku-docker \
    --repository-format=docker \
    --location=asia-northeast1 \
    --project=gke-test-287910
```

## Alternative: Deploy Components Individually

If Terraform continues to fail, you can create resources manually:

### 1. Create VPC Network

```bash
gcloud compute networks create roudoku-vpc \
    --subnet-mode=custom \
    --project=gke-test-287910

gcloud compute networks subnets create roudoku-subnet \
    --network=roudoku-vpc \
    --region=asia-northeast1 \
    --range=10.0.0.0/24
```

### 2. Create Cloud SQL Instance

```bash
gcloud sql instances create roudoku-db-dev \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=asia-northeast1 \
    --network=projects/gke-test-287910/global/networks/roudoku-vpc
```

### 3. Create Firestore Database

```bash
gcloud firestore databases create \
    --location=asia-northeast1 \
    --type=firestore-native
```

### 4. Create Storage Buckets

```bash
# Content bucket
gsutil mb -p gke-test-287910 -c STANDARD -l ASIA-NORTHEAST1 gs://roudoku-content-dev

# Audio bucket  
gsutil mb -p gke-test-287910 -c STANDARD -l ASIA-NORTHEAST1 gs://roudoku-audio-dev

# Backup bucket
gsutil mb -p gke-test-287910 -c STANDARD -l ASIA-NORTHEAST1 gs://roudoku-backup-dev
```

## What to Do Next

1. **If authentication is fixed**: Run `./init-terraform.sh` to initialize Terraform properly
2. **If Terraform works**: Continue with the automated deployment
3. **If issues persist**: Use the manual commands above to create resources

## Checking Deployment Status

```bash
# Check what's been created
gcloud compute networks list
gcloud sql instances list
gcloud storage buckets list
gcloud run services list --region=asia-northeast1
```

## Need Help?

The authentication issue is likely due to:
- Expired tokens
- Wrong Google account
- Missing permissions

Try running this in order:
1. `gcloud auth login` (use the account that owns gke-test-287910)
2. `gcloud auth application-default login` (same account)
3. `gcloud config set project gke-test-287910`
4. Then retry the deployment