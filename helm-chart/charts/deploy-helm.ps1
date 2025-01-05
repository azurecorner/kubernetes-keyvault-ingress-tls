$webApiChartName = "webapi"
$ingressChartName="ingress" 
$webappChartName = "webapp"
$secretProviderChartName = "secrets"
$NAMESPACE = "ingress-nginx"
$RESOURCE_GROUP_NAME = "RG-AKS-INGRESS-TLS"
$RESOURCE_GROUP_LOCATION = "eastus"
$CLUSTER_NAME = "aks-ingress-tls"
$INGRESS_NAME="ingress-datasynchro"
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl get deployments --all-namespaces=true
# az network vnet check-ip-address --name $VNET_NAME -g $RESOURCE_GROUP_NAME --ip-address $PRIVATE_IP
Write-Host "Verify the Azure Key Vault provider for Secrets Store CSI Driver installation..." -ForegroundColor Green
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'
# Add the ingress-nginx Helm repository if not already added

$TENANT_ID = "f12a747a-cddf-4426-96ff-ebe055e215a3"
write-host "Getting the user-assigned identity ID for the Azure Key Vault provider for Secrets Store CSI Driver..." -ForegroundColor Green
$AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID=az identity show --resource-group "MC_$($RESOURCE_GROUP_NAME)_$($CLUSTER_NAME)_$($RESOURCE_GROUP_LOCATION)"  --name "azurekeyvaultsecretsprovider-$CLUSTER_NAME" --query 'clientId'
write-host "User-assigned identity ID: $AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID" -ForegroundColor Green

Write-Host "Deploying Secret provider chart..." -ForegroundColor Green

kubectl create namespace $NAMESPACE
helm upgrade --install secrets-provider $secretProviderChartName  --set tenantId=$TENANT_ID  --set userAssignedIdentityID=$AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID

write-host "Waiting for the secret-provider pod to be ready... " -ForegroundColor Green
kubectl get SecretProviderClass -n $NAMESPACE 

Write-Host "Adding the ingress-nginx repository..." -ForegroundColor Green
 # Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update the Helm repo to ensure we have the latest charts
helm repo update

 Write-Host "Deploying the NGINX ingress controller..." -ForegroundColor Green
# Deploy the NGINX ingress controller with an external load balancer

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx  `
    --namespace $NAMESPACE  `
    --create-namespace  `
    --set controller.replicaCount=2  `
    --set controller.nodeSelector."kubernetes\.io/os"=linux  `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux  `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz  `
    -f extra-volumes.yaml

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

kubectl get secret -n $NAMESPACE

#Check the status of the pods to see if the ingress controller is online.
kubectl get pods -n $NAMESPACE

#Now let's check to see if the service is online. This of type LoadBalancer, so do you have an EXTERNAL-IP?
kubectl get services -n $NAMESPACE

Write-Host "Deploying web api chart..." -ForegroundColor Green

helm upgrade --install datasynchro-api $webApiChartName 

Write-Host "Deploying web app chart..." -ForegroundColor Green

helm upgrade --install datasynchro-app $webappChartName 

write-host "Waiting for the logcorner-command pod to be ready... " -ForegroundColor Green

kubectl wait --namespace  $NAMESPACE --for=condition=ready pod -l app=datasynchro-api-http-api --timeout=300s
kubectl wait --namespace  $NAMESPACE --for=condition=ready pod -l app=datasynchro-app-http-app --timeout=300s

kubectl get pods --namespace  $NAMESPACE

Write-Host "Deploying Ingress chart..." -ForegroundColor Green

helm upgrade --install ingress $ingressChartName 

write-host "Waiting for the ingress pod to be ready... " -ForegroundColor Green
kubectl describe ingressclasses nginx
kubectl get services -n $NAMESPACE
kubectl describe ingress $INGRESS_NAME -n $NAMESPACE

write-host "ping  $externalIP .. " -ForegroundColor Green
ping $externalIP

write-host "Calling web app : app.cloud-devops-craft.com:443:$externalIP ... " -ForegroundColor Green
 
 # Define the curl command
$response = & "C:\Windows\System32\curl.exe" -s -o NUL -w "%{http_code}" -k --resolve app.cloud-devops-craft.com:443:$externalIP https://app.cloud-devops-craft.com

# Output the status code
Write-Output "Status Code: $response"

Write-Host "Calling web api  for all weatherforecast : https://api.cloud-devops-craft.com/api/weatherforecast ... " -ForegroundColor Green

& "C:\Windows\System32\curl.exe" -v -k --resolve api.cloud-devops-craft.com:443:$externalIP  https://api.cloud-devops-craft.com/api/weatherforecast

Write-Host "Calling web api  for weatherforecast by id ... " -ForegroundColor Green

& "C:\Windows\System32\curl.exe" -v -k --resolve api.cloud-devops-craft.com:443:$externalIP  https://api.cloud-devops-craft.com/api/weatherforecast/1


  


  