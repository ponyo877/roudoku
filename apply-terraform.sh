#!/bin/bash
# Apply Terraform configuration

set -e

cd terraform

echo "Applying Terraform configuration..."
echo "==================================="

# Generate fresh plan with main environment
echo "Generating deployment plan..."
terraform plan -var-file=environments/main/terraform.tfvars -out=tfplan

echo ""
echo "This will deploy infrastructure to project gke-test-287910"
echo "Environment: main (cost-optimized)"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [[ $confirm == "yes" ]]; then
    terraform apply tfplan
    echo ""
    echo "✅ Infrastructure deployment complete!"
    echo ""
    echo "Next steps:"
    echo "1. Run database migrations: ./scripts/setup-database.sh"
    echo "2. Set up Firebase authentication"
    echo "3. Deploy your API: gcloud builds submit --config cloudbuild.yaml"
else
    echo "Deployment cancelled."
    exit 1
fi