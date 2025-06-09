# Single Environment Architecture (Cost-Optimized)

## Current Status
Using **single environment** approach in project `gke-test-287910` to minimize costs.

## Environment Configuration

### Single Environment: Main
- **Project**: `gke-test-287910`
- **Environment**: `main`
- **Configuration**: `terraform/environments/main/terraform.tfvars`
- **Purpose**: Development, testing, and production in one environment
- **Resources**: Cost-optimized configuration

## Deployment Commands

```bash
# Deploy infrastructure (single environment)
./apply-terraform.sh

# Or manually:
cd terraform
terraform plan -var-file=environments/main/terraform.tfvars
terraform apply -var-file=environments/main/terraform.tfvars
```

## Cost-Optimized Features

- **Single environment**: No dev/prod separation
- **Minimal resources**: `db-f1-micro` database, minimal Cloud Run instances
- **No backups**: Database backups disabled to save costs
- **Auto-scaling**: Cloud Run scales to zero when not in use
- **Shared usage**: Development and production traffic in same environment

## Resource Overview

Current deployment creates:
- **Database**: Cloud SQL PostgreSQL (db-f1-micro, 10GB)
- **Compute**: Cloud Run services (0-5 instances, 512Mi memory)
- **Storage**: 3 Cloud Storage buckets
- **CI/CD**: Cloud Build and Artifact Registry
- **Monitoring**: Basic alerts and logging
- **Estimated cost**: ~$15-20/month

## Cost Savings Compared to Multi-Environment

- **No environment duplication**: -50% infrastructure costs
- **No staging environment**: -$15-20/month
- **Minimal resources**: -30% per-service costs
- **No environment-specific networking**: -$5-10/month

## Scaling Strategy

When traffic increases:
1. Increase Cloud Run max instances (currently 5)
2. Upgrade database tier (currently db-f1-micro)
3. Enable database backups if needed
4. Add read replicas if necessary

This single-environment approach can handle significant traffic before requiring separation.