# Troubleshooting Google Cloud Authentication

## The "invalid_grant" Error

This error typically occurs when:
1. Your authentication tokens have expired
2. You're using the wrong Google account
3. Application default credentials are outdated

## Solution Steps

### 1. Clear Existing Credentials

```bash
# Remove existing application default credentials
rm -rf ~/.config/gcloud/application_default_credentials.json

# Clear gcloud configuration
gcloud auth revoke --all
```

### 2. Re-authenticate

```bash
# Login to gcloud
gcloud auth login

# Set the project
gcloud config set project gke-test-287910

# Login for application default credentials (required for Terraform)
gcloud auth application-default login
```

### 3. Verify Authentication

```bash
# Check active account
gcloud auth list

# Check current project
gcloud config get-value project

# Test access to the state bucket
gsutil ls gs://gke-test-287910-terraform-state/
```

### 4. Initialize Terraform

```bash
cd terraform

# Remove old state
rm -rf .terraform
rm -f .terraform.lock.hcl

# Re-initialize
terraform init
```

## Alternative: Use Service Account

If personal authentication continues to fail, use a service account:

### 1. Create Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account" \
    --project=gke-test-287910

# Grant necessary roles
gcloud projects add-iam-policy-binding gke-test-287910 \
    --member="serviceAccount:terraform-sa@gke-test-287910.iam.gserviceaccount.com" \
    --role="roles/owner"

# Create key
gcloud iam service-accounts keys create ~/terraform-key.json \
    --iam-account=terraform-sa@gke-test-287910.iam.gserviceaccount.com
```

### 2. Use Service Account

```bash
# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json

# Initialize Terraform
cd terraform
terraform init
```

## Common Issues and Solutions

### Issue: "Permission denied" on state bucket
**Solution**: Ensure your account has Storage Admin role:
```bash
gcloud projects add-iam-policy-binding gke-test-287910 \
    --member="user:your-email@example.com" \
    --role="roles/storage.admin"
```

### Issue: "API not enabled" errors
**Solution**: Enable the required API:
```bash
gcloud services enable [API_NAME].googleapis.com
```

### Issue: Terraform state lock
**Solution**: Force unlock if needed:
```bash
terraform force-unlock [LOCK_ID]
```

## Verification Commands

```bash
# Check bucket access
gsutil ls gs://gke-test-287910-terraform-state/

# Check project APIs
gcloud services list --enabled

# Test Terraform
cd terraform
terraform validate
```

## Quick Fix Script

Save this as `fix-auth.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ID="gke-test-287910"

echo "Fixing authentication for $PROJECT_ID..."

# Revoke existing credentials
gcloud auth revoke --all 2>/dev/null || true

# Remove application default credentials
rm -rf ~/.config/gcloud/application_default_credentials.json

# Re-authenticate
echo "Please login with your Google account..."
gcloud auth login

# Set project
gcloud config set project $PROJECT_ID

# Get application default credentials
echo "Please login again for application credentials..."
gcloud auth application-default login

# Verify
echo "Current account:"
gcloud auth list
echo ""
echo "Current project:"
gcloud config get-value project
echo ""
echo "Testing bucket access..."
gsutil ls gs://${PROJECT_ID}-terraform-state/ || echo "Bucket access failed"

echo "Authentication fix complete!"
```