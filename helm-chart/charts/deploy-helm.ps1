$ChartName = "webapi"
$IMAGE_TAG = "1217"
$NAMESPACE = "ingress-nginx"
$RESOURCE_GROUP_NAME = "RG-AKS-INGRESS-TLS"
$CLUSTER_NAME = "aks-ingress-tls"
$WORKLOAD_NAMESPACE = "default"
$INGRESS_NAME="ingress-datasynchro"
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl get deployments --all-namespaces=true
# az network vnet check-ip-address --name $VNET_NAME -g $RESOURCE_GROUP_NAME --ip-address $PRIVATE_IP
Write-Host "Verify the Azure Key Vault provider for Secrets Store CSI Driver installation..." -ForegroundColor Green
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'
# Add the ingress-nginx Helm repository if not already added
Write-Host "Adding the ingress-nginx repository..." -ForegroundColor Green
 # Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update the Helm repo to ensure we have the latest charts
helm repo update

Write-Host "Deploying the NGINX ingress controller..." -ForegroundColor Green
# Deploy the NGINX ingress controller with an external load balancer

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx  `
    --namespace $NAMESPACE  `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."kubernetes\.io/os"=linux  `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz  `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux

$ServiceName = "ingress-nginx-controller"

Write-Host "Waiting for external IP for service '$ServiceName' in namespace '$NAMESPACE'..." -ForegroundColor Green

do {
    $externalIP = kubectl get service $ServiceName --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if (-not $externalIP) {
        Write-Host "External IP is still pending. Retrying in 5 seconds..."
        Start-Sleep -Seconds 5
    }
} while (-not $externalIP)

Write-Host "Service is ready! External IP: $externalIP" -ForegroundColor Green

#Check the status of the pods to see if the ingress controller is online.
kubectl get pods --namespace ingress-nginx

#Now let's check to see if the service is online. This of type LoadBalancer, so do you have an EXTERNAL-IP?
kubectl get services --namespace ingress-nginx

#Deploy an additional Helm chart (logcorner-command)
Write-Host "Deploying logcorner-command chart..." -ForegroundColor Green

helm upgrade --install datasynchro-api $ChartName 

$webappChartName = "webapp"
helm upgrade --install datasynchro-app $webappChartName 

write-host "Waiting for the logcorner-command pod to be ready... " -ForegroundColor Green

#kubectl wait --for=condition=ready pod -l app=http-api --timeout=300s

kubectl get pods --namespace  $WORKLOAD_NAMESPACE

kubectl describe ingressclasses nginx
kubectl get services --namespace ingress-nginx
kubectl describe ingress $INGRESS_NAME

write-host "Calling web app ... " -ForegroundColor Green
curl -v http://$externalIP/ -Headers @{ "Host" = "app.ingress.cloud-devops-craft.com" }

Write-Host "Calling web api... " -ForegroundColor Green
curl -v http://$externalIP/api/weatherforecast -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" }

<# curl -v http://localhost:5166/api/WeatherForecast
curl -v http://localhost:5166/api/WeatherForecast/1


Invoke-WebRequest -Uri "http://localhost:5166/api/WeatherForecast" -Method POST -Headers @{ "Content-Type" = "application/json" } -Body '{
    "Date": "2024-12-19",
    "TemperatureC": 22,
    "Summary": "Warm"
}'

Invoke-WebRequest -Uri "http://localhost:5166/api/WeatherForecast" -Method PUT -Headers @{ "Content-Type" = "application/json" } -Body '{
    "Date": "2024-12-19",
    "TemperatureC": 22,
    "Summary": "Warm"
}'


Invoke-WebRequest -Uri "http://localhost:5166/api/WeatherForecast/1" -Method DELETE -Headers @{ "Content-Type" = "application/json" } #>


