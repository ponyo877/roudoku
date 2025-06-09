#!/bin/bash

# Deployment script for cost-optimized Aozora StoryWalk infrastructure
# Single environment setup with minimal VPC configuration

set -e

PROJECT_ID="gke-test-287910"
REGION="asia-northeast1"
ENVIRONMENT="main"

echo "🚀 Starting deployment for project: $PROJECT_ID"

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null; then
    echo "❌ Not authenticated with gcloud. Please run 'gcloud auth login'"
    exit 1
fi

# Set project
echo "📋 Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -var-file="environments/main/terraform.tfvars" -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT"

# Confirm deployment
read -p "🚀 Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying Terraform configuration..."
    terraform apply -var-file="environments/main/terraform.tfvars" -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve
    
    echo "✅ Deployment completed successfully!"
    
    # Output important information
    echo ""
    echo "📊 Infrastructure Summary:"
    echo "========================="
    terraform output
    
    echo ""
    echo "🔗 Important URLs:"
    echo "API Service: $(terraform output -raw api_service_url 2>/dev/null || echo 'Not available')"
    echo ""
    echo "💰 Estimated monthly cost: ~$28 (79% reduction from original $133)"
    echo ""
    echo "📝 Next steps:"
    echo "1. Update mobile app constants with the API URL above"
    echo "2. Set up CI/CD GitHub connection"
    echo "3. Deploy application code via Cloud Build"
    
else
    echo "❌ Deployment cancelled"
    exit 1
fi