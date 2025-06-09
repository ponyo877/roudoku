#!/bin/bash
# Test Terraform configuration after fixes

set -e

cd terraform

echo "Running Terraform validate..."
terraform validate

echo ""
echo "Running Terraform plan..."
terraform plan -var-file=environments/main/terraform.tfvars -out=tfplan

echo ""
echo "Terraform plan completed successfully!"
echo ""
echo "Review the plan above. If everything looks good, run:"
echo "  cd terraform && terraform apply tfplan"
echo "  Or use: ./apply-terraform.sh"