terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
  
  backend "s3" {
    # These values will be provided at terraform init via a backend config file
    # Example: terraform init -backend-config=backend.hcl
    # bucket         = "tfstate-bucket-name"
    # key            = "devopstht-ecr/terraform.tfstate"
    # region         = "eu-west-1"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "THT-DevOps"
      ManagedBy   = "Terraform"
    }
  }
}
