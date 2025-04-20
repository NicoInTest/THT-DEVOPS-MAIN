#!/bin/bash
# This script bootstraps the remote state infrastructure

# Ensure AWS_ACCOUNT_ID is set
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Please set the AWS_ACCOUNT_ID environment variable"
  exit 1
fi

# Create a temporary directory for the bootstrap config
mkdir -p .bootstrap

# Create a bootstrap terraform file
cat > .bootstrap/main.tf <<EOF
provider "aws" {
  region = "eu-west-1"
}

module "remote_state" {
  source = "../modules/remote_state"
  
  environment = "devopstht"
  account_id  = "$AWS_ACCOUNT_ID"
}

output "s3_bucket_name" {
  value = module.remote_state.s3_bucket_name
}

output "dynamodb_table_name" {
  value = module.remote_state.dynamodb_table_name
}
EOF

# Initialize and apply
cd .bootstrap
terraform init
terraform apply -auto-approve

# Create the backend.hcl file with actual values
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

cd ..
cat > backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "devopstht/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

# Copy remote state modules and backend.hcl to other terraform workspaces
# This ensures consistent state management across all workspaces
if [ -d ../../ecr/terraform ]; then
  echo "Copying remote state configuration to ECR workspace..."
  
  # Create the remote_state module if it doesn't exist
  mkdir -p ../../ecr/terraform/modules/remote_state
  
  # Copy the remote_state module files
  cp -r ./modules/remote_state/* ../../ecr/terraform/modules/remote_state/
  
  # Create ECR backend.hcl
  cat > ../../ecr/terraform/backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "devopstht-ecr/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

  # Make the deploy script executable
  if [ -f ../../ecr/terraform/deploy.sh ]; then
    chmod +x ../../ecr/terraform/deploy.sh
  fi
fi

echo "Remote state infrastructure created successfully!"
echo "Run 'terraform init -backend-config=backend.hcl' to initialize the backend"

# Clean up
rm -rf .bootstrap 