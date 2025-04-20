aws_region = "eu-west-1"
environment = "devopstht"
vpc_cidr = "10.124.0.0/20"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnets_cidr = ["10.124.0.0/23", "10.124.2.0/23", "10.124.4.0/23"]
private_subnets_cidr = ["10.124.6.0/23", "10.124.8.0/23", "10.124.10.0/23"]
# Images should be provided at runtime, e.g. using shell script:
# order_api_image = "${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/devopstht-order-api:latest"
# processor_image = "${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/devopstht-order-processor:latest"
# order_api_repo_arn = "arn:aws:ecr:eu-west-1:${AWS_ACCOUNT_ID}:repository/devopstht-order-api"
# order_processor_repo_arn ="arn:aws:ecr:eu-west-1:${AWS_ACCOUNT_ID}:repository/devopstht-order-processor"
