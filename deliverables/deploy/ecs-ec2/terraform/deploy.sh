#!/bin/bash
# This script deploys the infrastructure using Terraform

# Exit on any error
set -e

# Ensure AWS_ACCOUNT_ID is set
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Please set the AWS_ACCOUNT_ID environment variable"
  exit 1
fi

# Set environment name, default to 'devopstht'
ENVIRONMENT=${ENVIRONMENT:-devopstht}
echo "Using environment: $ENVIRONMENT"

# Create variables file with account ID and environment substituted
TMP_VARS_FILE=$(mktemp)
cat > "$TMP_VARS_FILE" <<EOF
$(cat default.tfvars | grep -v "^environment =")
environment = "$ENVIRONMENT"
order_api_image = "${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-api:latest"
processor_image = "${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-processor:latest"
order_api_repo_arn = "arn:aws:ecr:eu-west-1:${AWS_ACCOUNT_ID}:repository/${ENVIRONMENT}-order-api"
order_processor_repo_arn ="arn:aws:ecr:eu-west-1:${AWS_ACCOUNT_ID}:repository/${ENVIRONMENT}-order-processor"
EOF

# Initialize terraform if requested
init_terraform() {
  # If backend.hcl exists, use it for initialization
  if [ -f backend.hcl ]; then
    # Substitute account ID in backend.hcl if needed
    if grep -q "\${ACCOUNT_ID}" backend.hcl; then
      TMP_BACKEND_FILE=$(mktemp)
      cat backend.hcl | sed "s/\${ACCOUNT_ID}/$AWS_ACCOUNT_ID/g" > "$TMP_BACKEND_FILE"
      # Add environment-specific prefix to the state key
      sed -i "s|key            = \"devopstht/terraform.tfstate\"|key            = \"$ENVIRONMENT/terraform.tfstate\"|" "$TMP_BACKEND_FILE"
      terraform init -backend-config="$TMP_BACKEND_FILE"
      rm "$TMP_BACKEND_FILE"
    else
      terraform init -backend-config=backend.hcl
    fi
  else
    echo "Warning: backend.hcl not found, using local state"
    terraform init
  fi
}

# Parse command line arguments
ACTION="plan"
if [ $# -ge 1 ]; then
  ACTION="$1"
fi

# Run Terraform with the specified action
case "$ACTION" in
  init)
    init_terraform
    ;;
  plan)
    init_terraform
    terraform plan -var-file="$TMP_VARS_FILE"
    ;;
  apply)
    init_terraform
    terraform apply -var-file="$TMP_VARS_FILE" -auto-approve
    ;;
  destroy)
    init_terraform
    terraform destroy -var-file="$TMP_VARS_FILE" -auto-approve
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Usage: $0 [init|plan|apply|destroy]"
    echo ""
    echo "Environment can be specified with the ENVIRONMENT variable:"
    echo "ENVIRONMENT=production $0 apply"
    exit 1
    ;;
esac

# Clean up temporary file
rm "$TMP_VARS_FILE" 