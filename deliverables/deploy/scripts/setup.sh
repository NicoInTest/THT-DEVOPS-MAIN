#!/bin/bash

# Exit on error
set -e

# Print commands as they are executed
set -x

# Current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../../.."
CHARTS_DIR="$SCRIPT_DIR/../kubernetes/charts"
APPS_DIR="$PROJECT_ROOT/starter/apps"

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "Starting Minikube..."
    minikube start
fi

# Point shell to minikube's docker daemon
echo "Configuring shell to use Minikube's Docker daemon..."
eval $(minikube docker-env)

# Build the Docker images
echo "Building Docker images..."
docker build -t order-api "$APPS_DIR/order-api" --progress plain
docker build -t order-processor "$APPS_DIR/order-processor" --progress plain

# Verify images are built and available to minikube
docker images | grep -E 'order-api|order-processor'

# Create namespaces
echo "Creating namespaces if they don't exist"
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace app-order --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the observability Helm chart
echo "Installing observability chart from $CHARTS_DIR/observability"
helm upgrade --install observability $CHARTS_DIR/observability \
  --namespace observability \
  --set skipNamespaceTemplate=true \
  --wait \
  --debug \
  --timeout 10m

# Install/upgrade the order-app Helm chart
echo "Installing order-app chart from $CHARTS_DIR/order-app"
helm upgrade --install order-app $CHARTS_DIR/order-app \
  --namespace app-order \
  --set skipNamespaceTemplate=true \
  --wait \
  --debug \
  --timeout 10m

echo "Deployment complete."
echo "You can check the pods with: kubectl get pods -n app-order"
echo ""
echo "You can access Grafana at:"
echo "kubectl port-forward svc/grafana 3000:3000 -n observability"
echo "Then visit http://localhost:3000"
echo ""
echo "You can access the Order API at:"
echo "kubectl port-forward svc/order-api 8000:8000 -n app-order"
echo "Then visit http://localhost:8000"

# Add a wait period to make sure DynamoDB is fully initialized
echo "Waiting for DynamoDB to be fully initialized..."
sleep 10

# Forward the DynamoDB port for verification
echo "To verify the DynamoDB setup, you can run:"
echo "kubectl port-forward svc/dynamodb-local 8088:8000 -n app-order &"
echo "Then run: aws dynamodb list-tables --endpoint-url http://localhost:8088" 