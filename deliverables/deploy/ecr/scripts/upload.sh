#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
APPS_DIR="${SCRIPT_DIR}/../../../../starter/apps"

ENVIRONMENT=${1:-devopstht}

# Make sure we have the region set
AWS_REGION=${AWS_DEFAULT_REGION:-eu-west-1}
echo "Using AWS region: ${AWS_REGION}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS Account ID: ${AWS_ACCOUNT_ID}"

# Initialize Terraform first
echo "Initializing Terraform..."
cd "${TERRAFORM_DIR}"
terraform init

# Get repository URLs
echo "Getting repository URLs from Terraform output..."
ORDER_API_REPO=$(terraform output -raw order_api_repository_url || echo "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-order-api")
ORDER_PROCESSOR_REPO=$(terraform output -raw order_processor_repository_url || echo "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-order-processor")

echo "Order API Repository: ${ORDER_API_REPO}"
echo "Order Processor Repository: ${ORDER_PROCESSOR_REPO}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push Order API image
echo "Building Order API image..."
cd "${APPS_DIR}"
docker build --platform linux/amd64 -t "${ORDER_API_REPO}:latest" ./order-api/

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TAG="${ORDER_API_REPO}:${TIMESTAMP}"
docker tag "${ORDER_API_REPO}:latest" "${TAG}"

ORDER_API_TAG="${TAG}"
echo "Pushing Order API image..."
docker push "${ORDER_API_REPO}:latest"
docker push "${TAG}"

# Build and push Order Processor image
echo "Building Order Processor image..."
docker build --platform linux/amd64 -t "${ORDER_PROCESSOR_REPO}:latest" ./order-processor/

TAG="${ORDER_PROCESSOR_REPO}:${TIMESTAMP}"
docker tag "${ORDER_PROCESSOR_REPO}:latest" "${TAG}"

echo "Pushing Order Processor image..."
docker push "${ORDER_PROCESSOR_REPO}:latest"
docker push "${TAG}"

echo "Pushed Order API Tag: ${ORDER_API_TAG}"
echo "Pushed Order Processor Tag: ${TAG}"
echo "Successfully built and pushed all images!" 