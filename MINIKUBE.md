# How to upload local images to Minikube 

eval $(minikube docker-env)
make docker-build 

# Deploy Helm chart 

make helm-apply


# Seed Dynamodb local

forward the port:
`kubectl port-forward deployment/dynamodb-local  8088:8000  &`

execute the init script, seed the database
`DDB_ENDPOINT=http://localhost:8088 python './starter/apps/scripts/init-dynamodb.py'`


# Connect to Order API

minikube service order-api --url # in one console to optain the service endpoint 

SERVER_ENDPOINT=localhost:58746 ./starter/apps/scripts/test_docker_compose.sh

# Install Grafana Monitoring 

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --namespace monitoring
## Expose Grafana
kubectl expose -n monitoring service grafana --type=NodePort --target-port=3000 --name=grafana-ext

minikube -n monitoring service grafana-ext

grafana password: ˜kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo˜

# install prometheus 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade -i prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistence.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2"

