include starter/apps/Makefile
include deliverables/deploy/ecs-ec2/terraform/Makefile

.PHONY: docker-build docker-build-api docker-build-processor helm-apply helm-restart helm-destroy minikube-setup k8s-deploy

all: minikube-setup

minikube-setup:
	@echo "Setting up Minikube for local development"
	@minikube start || echo "Minikube already running"
	@eval $$(minikube docker-env) && echo "Minikube Docker environment configured"
	@echo "Run 'make docker-build' followed by 'make k8s-deploy' to deploy"

minikube-wsl-setup:
	@echo "Setting up Minikube for local development"
	@minikube start --driver=docker --ports='127.0.0.1:30001:30001,127.0.0.1:30300:30300' || echo "Minikube already running"
	@eval $$(minikube docker-env) && echo "Minikube Docker environment configured"
	@echo "Run 'make docker-build' followed by 'make k8s-deploy' to deploy"

docker-build-api:
	@eval $$(minikube docker-env) && docker build --progress plain -t order-api starter/apps/order-api/. 

docker-build-processor:
	@eval $$(minikube docker-env) && docker build --progress plain -t order-processor starter/apps/order-processor/. 

docker-build: docker-build-api docker-build-processor

helm-destroy:
	@helm uninstall observability -n observability || true
	@helm uninstall order-app -n app-order || true

helm-apply:
	@echo "Creating namespaces..."
	@kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace app-order --dry-run=client -o yaml | kubectl apply -f -
	@echo "Installing observability chart..."
	@helm upgrade --install observability ./deliverables/deploy/kubernetes/charts/observability/ \
		--namespace observability \
		--set skipNamespaceTemplate=true
	@echo "Installing order-app chart..."
	@helm upgrade --install order-app ./deliverables/deploy/kubernetes/charts/order-app/ \
		--namespace app-order \
		--set skipNamespaceTemplate=true

helm-restart: helm-destroy
	@sleep 10
	@make helm-apply

k8s-deploy: docker-build helm-apply
	@echo "Application deployed to Kubernetes!"
	@echo "You can access the Order API by running:"
	@echo "kubectl port-forward svc/order-api 8000:8000 -n app-order"
	@echo "Then visit http://localhost:8000"

ddb-seed:
	@kubectl port-forward svc/dynamodb-local 8088:8000 -n app-order &
	@sleep 3
	@DDB_ENDPOINT=http://localhost:8088 python './starter/apps/scripts/init-dynamodb.py'
	@pkill -f "kubectl port-forward svc/dynamodb-local" || true
