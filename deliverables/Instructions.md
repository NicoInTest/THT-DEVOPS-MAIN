# Terraform and ECS-EC2 cluster
## Initial Setup - Remote State Management

Before deploying any Terraform resources, set up the remote state infrastructure:

```bash
# Navigate to the terraform directory
cd deliverables/deploy/ecs-ec2/terraform
```

```bash
# Create backend.hcl for remote state backend
touch backend.hcl
```

```
# Example of backend.hcl file
bucket         = "tfstate-devopstht-<account_id>"
key            = "devopstht-ecr/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-state-lock-devopstht"
encrypt        = true
```

```
# Set your AWS account ID
AWS_ACCOUNT_ID=<account_id>

# Using Makefile (recommended)
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make bootstrap

# Or using the script directly
chmod +x bootstrap_remote_state.sh
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID ./bootstrap_remote_state.sh
```

This creates:
- An S3 bucket for storing Terraform state files
- A DynamoDB table for state locking
- Backend configuration for all Terraform workspaces

## Using the Makefile

The project includes a Makefile that simplifies common operations:

```bash
# Navigate to the terraform directory
cd deliverables/deploy/ecs-ec2/terraform
```

```bash
# Create backend.hcl for remote state backend
touch backend.hcl
```

```
# Example of backend.hcl file
bucket         = "tfstate-devopstht-<account_id>"
key            = "devopstht-ecr/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-state-lock-devopstht"
encrypt        = true
```

```
# Set your AWS account ID
AWS_ACCOUNT_ID=<account_id>

# Initialize Terraform for a specific environment
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-init ENVIRONMENT=production

# Plan changes
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-plan ENVIRONMENT=production

# Apply changes
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply ENVIRONMENT=production

# Destroy infrastructure
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-destroy ENVIRONMENT=production

# For ECR repositories
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-init ENVIRONMENT=production
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-plan ENVIRONMENT=production
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-apply ENVIRONMENT=production
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-destroy ENVIRONMENT=production
```

NOTE: If you don't specify an ENVIRONMENT, it defaults to "devopstht"

## Multi-Environment Support

All deployment scripts support specifying different environments via the `ENVIRONMENT` variable:

```bash
# Set your AWS account ID
AWS_ACCOUNT_ID=<account_id>

# Deploy to the default environment (devopstht)
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply

# Deploy to a different environment (e.g., production)
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply ENVIRONMENT=production

# Deploy to staging
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply ENVIRONMENT=staging
```

Each environment uses:
- Separate state files in the shared S3 bucket
- Consistent naming conventions with environment prefixes
- The same DynamoDB table for state locking to prevent concurrent modifications

## ECR Repositories Deployment

First, deploy the ECR repositories that will store the container images:

```bash
# Navigate to the project root
cd deliverables/deploy/ecs-ec2/terraform

# Set your AWS account ID
AWS_ACCOUNT_ID=<account_id>

# Deploy ECR repositories for the default environment
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-apply

# Or deploy to a specific environment
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-ecr-apply ENVIRONMENT=production
```

## Docker Images Build and Push
- Build and push Docker images for both services to ECR:
  ```bash
  # Set your AWS account ID
  AWS_ACCOUNT_ID=<account_id>
  
  # Set the environment (optional, defaults to devopstht)
  ENVIRONMENT=${ENVIRONMENT:-devopstht}
  
  # Navigate to the apps directory
  cd starter/apps
  
  # Build the images
  docker build -t order-api ./order-api/
  docker build -t order-processor ./order-processor/
  
  # Tag and push to ECR
  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com
  
  docker tag order-api:latest ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-api:latest
  docker tag order-processor:latest ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-processor:latest
  
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-api:latest
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${ENVIRONMENT}-order-processor:latest
  ```

## ECS-EC2 Infrastructure Deployment

After the ECR repositories and Docker images are ready, deploy the ECS infrastructure:

```bash
# Navigate to the terraform directory
cd deliverables/deploy/ecs-ec2/terraform

# Set your AWS account ID
AWS_ACCOUNT_ID=<account_id>

# Deploy to the default environment
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply

# Or deploy to a specific environment 
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID make tf-apply ENVIRONMENT=production
```

## How to Test 
- After deployment, Terraform will output the ALB DNS name for the Order API
- Use curl or a web browser to check the health endpoint:
  ```bash
  curl http://<ALB_DNS_NAME>/health
  ```

- Create a test order:
  ```bash
  curl -X POST http://<ALB_DNS_NAME>/orders/ \
    -H "Content-Type: application/json" \
    -d '{
        "product_id": "PROD001",
        "quantity": 1,
        "customer_id": "CUST001"
    }'
  ```
- Verify the order was created by retrieving it using the order_id returned from the previous command:
  ```bash
  curl http://<ALB_DNS_NAME>/orders/<ORDER_ID>
  ```

## Security Features
- **HTTPS Support**: All traffic is automatically redirected from HTTP to HTTPS
- **Self-signed Certificate**: For test purposes, a self-signed certificate is used. In production, use a valid certificate from a trusted CA
- **Secure Security Groups**: Inbound and outbound traffic is restricted to only what's needed
- **VPC Endpoints**: Traffic to AWS services stays within the AWS network

# Kubernetes and Helm
## How to deploy to MiniKube

### Simplified using MAKE
```bash
make minikube-wsl-setup
make docker-build
make helm-apply
```
Note: If you prefer not to use make, follow the steps below.

### For WSL2 Users with Docker Driver
When using minikube with Docker driver in WSL2, you need to start minikube with specific port mappings to access NodePort services:

```bash
# Start Minikube with port mappings for NodePorts:
# - Maps NodePort 30001 (order-api) to localhost:30001
# - Maps NodePort 30300 (Grafana) to localhost:30300
minikube start --driver=docker --ports='127.0.0.1:30001:30001,127.0.0.1:30300:30300'
```

This command does the following:
- `--driver=docker`: Uses the Docker driver for minikube (default for WSL2)
- `--ports='127.0.0.1:30001:30001'`: Maps the NodePort 30001 from minikube to port 30001 on your WSL2 localhost
- `--ports='127.0.0.1:30300:30300'`: Maps the NodePort 30300 from minikube to port 30300 on your WSL2 localhost

With these port mappings:
- You'll be able to access the order-api at http://127.0.0.1:30001
- You'll be able to access Grafana at http://127.0.0.1:30300

### For Other Environments
If you're not using WSL2 with Docker driver, you can start minikube normally:

```bash
minikube start
```

### Continue with Deployment
- Set up Docker to use Minikube's Docker daemon:
  ```bash
  eval $(minikube docker-env)
  ```

- Build the Docker images for both services:
  ```bash
  cd starter/apps
  
  # Build the images with tags that match our values.yaml
  docker build -t order-api:latest ./order-api/
  docker build -t order-processor:latest ./order-processor/
  ```

- Deploy the Helm chart:
  ```bash
  cd ../..  # Return to project root
  helm upgrade --install devopstht ./deliverables/deploy/kubernetes/charts/microservices/
  ```

- The deployment includes a job that initializes the DynamoDB tables. This job runs as a Helm hook and is automatically deleted after completion. If you want to view the logs, you'll need to create the job manually:
  ```bash
  # Create the job manually
  kubectl apply -f deliverables/deploy/kubernetes/charts/microservices/templates/dynamodb-init-job.yaml
  
  # Check the job status
  kubectl get jobs
  
  # View the logs
  kubectl logs job/dynamodb-init
  ```

## How to Test 
### Important Note for Docker Driver Users
If you're using the Docker driver with Minikube (default on Linux/WSL), the `minikube service --url` command will block your terminal as it sets up port forwarding. You have two options:

#### Option 1: Use two terminals (recommended for most environments)
- In terminal 1, run this command and keep it open:
  ```bash
  minikube service order-api --url
  # This will output a URL like http://127.0.0.1:42231 and keep running
  ```

- In terminal 2, use the URL displayed in terminal 1:
  ```bash
  # Use the URL from terminal 1 (example below)
  curl http://127.0.0.1:42231/health
  ```

#### Option 2: Use localhost with NodePort directly (recommended for WSL2)
If you started minikube with the port forwarding option as described above, you can access the service directly:

```bash
# Access using localhost and NodePort (30001)
curl http://127.0.0.1:30001/health
```

#### Option 3: Use minikube's IP with NodePort
- Get the NodePort and Minikube IP:
  ```bash
  kubectl get svc order-api -o jsonpath='{.spec.ports[0].nodePort}'
  minikube ip
  ```

- Access using the NodePort (typically 30001 as configured in values.yaml):
  ```bash
  curl http://$(minikube ip):30001/health
  ```

### Testing the API
- Test the health endpoint:
  ```bash
  # If using option 1, use the URL from terminal 1
  curl http://127.0.0.1:42231/health
  
  # If using option 2 (WSL2 with port mapping)
  curl http://127.0.0.1:30001/health
  
  # If using option 3
  curl http://$(minikube ip):30001/health
  ```

- Create a test order:
  ```bash
  # If using option 1, use the URL from terminal 1
  curl -X POST http://127.0.0.1:42231/orders/ \
    -H "Content-Type: application/json" \
    -d '{
        "product_id": "PROD001",
        "quantity": 1,
        "customer_id": "CUST001"
    }'
    
  # If using option 2 (WSL2 with port mapping)
  curl -X POST http://127.0.0.1:30001/orders/ \
    -H "Content-Type: application/json" \
    -d '{
        "product_id": "PROD001",
        "quantity": 1,
        "customer_id": "CUST001"
    }'
    
  # If using option 3
  curl -X POST http://$(minikube ip):30001/orders/ \
    -H "Content-Type: application/json" \
    -d '{
        "product_id": "PROD001",
        "quantity": 1,
        "customer_id": "CUST001"
    }'
  ```

- Verify the order was created by retrieving it with the order_id from the previous response:
  ```bash
  # Replace <ORDER_ID> with the actual order ID returned
  
  # If using option 1
  curl http://127.0.0.1:42231/orders/<ORDER_ID>
  
  # If using option 2 (WSL2 with port mapping)
  curl http://127.0.0.1:30001/orders/<ORDER_ID>
  
  # If using option 3
  curl http://$(minikube ip):30001/orders/<ORDER_ID>
  ```

- For automated testing, you'll need to modify the test script to use the correct URL:
  ```bash
  # If using option 1, set SERVER_ENDPOINT to the URL from terminal 1
  SERVER_ENDPOINT=http://127.0.0.1:42231 ./starter/apps/scripts/test_docker_compose.sh
  
  # If using option 2 (WSL2 with port mapping)
  SERVER_ENDPOINT=http://127.0.0.1:30001 ./starter/apps/scripts/test_docker_compose.sh
  
  # If using option 3
  SERVER_ENDPOINT=http://$(minikube ip):30001 ./starter/apps/scripts/test_docker_compose.sh
  ```

# Observability Stack

## How to Deploy the Monitoring Stack
The Prometheus and Grafana monitoring stack is included in the Helm chart and will be deployed automatically when you install the chart. The stack includes:

- Prometheus for metrics collection
- Grafana for visualization
- Pre-configured dashboards for monitoring Kubernetes and microservices

### Accessing Grafana

#### For WSL2 Users with Docker Driver
If you started minikube with the port mapping for Grafana as described above, you can access Grafana directly:

```bash
# Open this URL in your browser
http://127.0.0.1:30300
```

#### For Other Environments
Use the minikube service command:

```bash
minikube service grafana -n monitoring --url
```

### Grafana credentials:
- Username: admin
- Password: admin

## Using the Dashboards
After logging into Grafana, you'll find two pre-configured dashboards:

1. **Kubernetes Overview**: Provides overall cluster metrics
   - Total pods, nodes, and namespaces
   - CPU and memory usage by namespace

2. **Microservices Dashboard**: Focused on the application services
   - Memory usage of microservices
   - CPU usage of microservices
   - Pod restarts
   - Pod status

## Adding Custom Metrics
If you want to add custom application metrics, follow these steps:

1. Instrument your Python application with Prometheus metrics library
2. Expose a /metrics endpoint in your services
3. Configure Prometheus to scrape these endpoints (already done in the default configuration)
4. Create custom Grafana dashboards using the collected metrics

# Security Considerations

## Network Security
The infrastructure has been designed with security best practices in mind:

- **VPC Configuration**: 
  - Private subnets for application workloads with no direct internet access
  - Public subnets only for load balancers and NAT gateways
  - VPC endpoints for AWS services to keep traffic within the AWS network

- **Security Groups**: 
  - Limited to the minimum required ports and protocols
  - Restricted outbound traffic following the principle of least privilege
  - Well-documented with descriptions explaining each rule's purpose

## IAM Permissions
IAM roles and policies follow the principle of least privilege:

- ECS execution role has permissions only to pull images and write logs
- Task roles have specific permissions for each service:
  - Order API can only access its specific DynamoDB table
  - Order Processor can only access the inventory table
  - Service discovery permissions are limited to essential actions

## AWS Service Access
Services are accessed securely through VPC endpoints where possible:

- Gateway endpoints for S3 and DynamoDB
- Interface endpoints for ECR, CloudWatch, SSM, and ECS services
- All endpoint security groups are restricted to only necessary communications