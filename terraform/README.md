# Roudoku Terraform Infrastructure

This Terraform configuration creates the complete Google Cloud Platform infrastructure for the Roudoku (青空 StoryWalk) application.

## Architecture

The infrastructure includes:

- **Networking**: VPC, subnets, NAT gateway, VPC connector
- **Database**: Cloud SQL PostgreSQL with private networking
- **Compute**: Cloud Run services for API and recommendation engine
- **Storage**: Cloud Storage buckets for content, audio, and backups
- **Messaging**: Pub/Sub topics and Cloud Tasks queues
- **Analytics**: Cloud Firestore for real-time analytics
- **AI/ML**: Vertex AI endpoints for recommendation engine
- **Monitoring**: Cloud Monitoring dashboards and alerts
- **Scheduling**: Cloud Scheduler jobs for ETL and ML training

## Prerequisites

1. **Google Cloud Project**: Create a GCP project with billing enabled
2. **APIs**: The following APIs will be automatically enabled:
   - Cloud Run API
   - Cloud SQL Admin API
   - Cloud Storage API
   - Pub/Sub API
   - Firestore API
   - Vertex AI API
   - Text-to-Speech API
   - Cloud Monitoring API
   - Cloud Logging API
   - Cloud Scheduler API
   - Cloud Tasks API
   - Cloud Build API
   - Secret Manager API
   - VPC Access API
   - Service Networking API

3. **Terraform**: Install Terraform >= 1.5
4. **gcloud CLI**: Install and authenticate with Google Cloud

## Quick Start

### 1. Set up authentication

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Create state storage bucket

```bash
# For development
gsutil mb gs://roudoku-terraform-state-dev
gsutil versioning set on gs://roudoku-terraform-state-dev

# For production
gsutil mb gs://roudoku-terraform-state-prod
gsutil versioning set on gs://roudoku-terraform-state-prod
```

### 3. Configure backend

Edit `backend.tf` and uncomment the appropriate bucket for your environment.

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan and apply

For development:
```bash
terraform plan -var-file="environments/main/terraform.tfvars"
terraform apply -var-file="environments/main/terraform.tfvars"
```

For production:
```bash
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Configuration

### Environment Variables

Copy and modify the appropriate `.tfvars` file:

- `environments/main/terraform.tfvars` - Development environment
- `environments/prod/terraform.tfvars` - Production environment

Key variables to update:
- `project_id`: Your GCP project ID
- `notification_email`: Email for monitoring alerts
- Resource sizing based on your needs

### Modules

The infrastructure is organized into modules:

- `modules/networking`: VPC, subnets, firewall rules
- `modules/database`: Cloud SQL PostgreSQL
- `modules/compute`: Cloud Run services
- `modules/storage`: Cloud Storage and Pub/Sub
- `modules/ai`: Firestore and Vertex AI
- `modules/monitoring`: Monitoring and alerting

## Outputs

After applying, you'll get important outputs including:

- Database connection details (stored in Secret Manager)
- Cloud Run service URLs
- Storage bucket names
- Monitoring dashboard URL

## Security

- Database uses private networking only
- Service accounts follow least privilege principle
- Secrets are stored in Secret Manager
- VPC connector provides secure Cloud Run to VPC access

## Cost Optimization

- Development environment uses minimal resources
- Production environment auto-scales based on demand
- Storage lifecycle policies automatically archive old data
- Alert policies help monitor costs

## Maintenance

### Regular Tasks

1. **Database Backups**: Automated daily backups (production)
2. **ETL Jobs**: Daily Aozora Bunko data sync via Cloud Scheduler
3. **ML Training**: Weekly model retraining via Cloud Scheduler
4. **Monitoring**: Check dashboard and alerts regularly

### Updates

To update the infrastructure:

1. Modify the relevant `.tf` files
2. Plan the changes: `terraform plan`
3. Apply the changes: `terraform apply`

## Troubleshooting

### Common Issues

1. **API not enabled**: Terraform will automatically enable required APIs
2. **Quota exceeded**: Check GCP quotas and request increases if needed
3. **Permission denied**: Ensure your account has the necessary IAM roles

### Useful Commands

```bash
# View current state
terraform show

# Import existing resources
terraform import google_project.main YOUR_PROJECT_ID

# Destroy infrastructure (BE CAREFUL!)
terraform destroy -var-file="environments/main/terraform.tfvars"
```

## Support

For issues with the Terraform configuration, check:

1. Google Cloud documentation
2. Terraform Google Provider documentation
3. Project issues and discussions