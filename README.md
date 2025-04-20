# DevOps Engineer Technical Assessment

This assessment is designed to evaluate your expertise in modern cloud infrastructure, container orchestration, and DevOps practices. You'll be building and deploying a microservices-based application that demonstrates your ability to create production-ready infrastructure and implement DevOps best practices.

*Note*: Please ensure you read this document until the end, all relevant information to complete this assessment is in this document.

## Overview

In this assessment, deploy a microservices application that processes orders and manages inventory. The system consists of two services that communicate with each other and interact with a DynamoDB database. You'll implement this solution using both AWS ECS-EC2 cluster and Kubernetes, along with a simple observability stack. 

## Resources Provided
- We provide the code for simple micro services, but you have to understand the code in order to complete the test (e.g the environment variables required for the service to operate), feel free to change code to make it work if something is not working. 
- We provide several terraform components, like network, ecs cluster, some IAM permissions to make sure you focus on the deployment of the services 
- We provide kubernetes Helm chart component for local dynamodb so you can focus on service deployments
- We provide some documentation to help the setup with Minikube but Minikube docs may be your friend if you get stuck

## Time Allocation

The assessment is divided into four main components, with an high level estimation for test completion:
- AWS Infrastructure with Terraform (60 minutes)
- Kubernetes Deployment with Helm (60 minutes)
- Observability Implementation (60 minutes)
- Documentation and Testing (60 minutes)

## Prerequisites

Before you begin, please ensure you have the following tools installed:

- AWS CLI configured with Free Tier account
- Docker Desktop
- Terraform 1.10+
- Kubernetes (Minikube v1.35+)
- Helm (v3.17+)
- Python 3.12+
- Git

## System Architecture

You will implement a system with the following components:

1. Order API Gateway (code is provided):
   - Handles incoming order requests
   - Communicates with Order Processor
   - Stores order data in DynamoDB
   - Implements health checks

2. Order Processor (code is provided):
   - Processes orders
   - Manages inventory in DynamoDB
   - Implements health checks

3. Infrastructure Components:
   - AWS ECS-EC2 cluster deployment
   - Kubernetes deployment with Helm
   - DynamoDB for data persistence
   - Observability stack (Prometheus, Grafana) integrated in Kubernetes to monitor K8s Cluster

## Requirements

### 1. AWS Infrastructure

Complete the Terraform configurations for AWS deployment that:
- Deploy services to AWS ECS-EC2 cluster
- Set up DynamoDB tables
- Configure networking and security
- Stay within AWS Free Tier limits

### 2. Kubernetes Deployment

Create Helm charts that:
- Deploy both services
- Configure service discovery
- Implement proper health checks
- Include local DynamoDB for development (code is provided)

### 3. Observability Stack

Implement comprehensive observability with:
- Kubernetes Metrics collection with Prometheus
- Grafana dashboards

### 4. Documentation and Testing

Provide thorough documentation including:
- Setup instructions
- Justification for your decisions 


1. Review the starter code in `starter` directory:

2. Start the local development environment provided inside `starter/apps`:
```bash
docker-compose up -d
```

3. Begin implementing the requirements in the order listed above.

## Example Local Development

The repository includes a Docker Compose setup for local development, to show how the services work together. check script `starter/apps/scripts/test_docker_compose.sh`:

## Evaluation Criteria

*Important Note*: Please use the `deliverables` folder structure to complete your tasks, if you need to change code in the services you can change the code in the `starter/apps` folder

Your submission will be evaluated based on:

1. Infrastructure Design:
   - AWS best practices
   - Kubernetes expertise
   - Security implementation

2. Observability Implementation:
   - Prometheus and Grafana setup
   - Dashboard configuration

3. Documentation Quality:
   - Setup instructions (check `Instructions.md`)
   - Decision justifications (check `DecisonsLog.md`)

## Submission Guidelines

1. Follow the structure of the `deliverables` folder 
2. Implement your solution following the requirements
3. Include all necessary documentation (instructions and decisions)
4. Ensure your solution can be deployed using the provided instructions
5. Send us the git repository url so we can access you solution  

## Important Notes

- Focus on quality over quantity
- Document your assumptions
- Consider security best practices
- Provide clear setup instructions
- Clean up AWS resources after testing if you test against an AWS account

## Support

The project as presented has been tested. Part of the evaluation involves being able to efficiently resolve potential errors or omissions, and keep a record of your decision making process.
