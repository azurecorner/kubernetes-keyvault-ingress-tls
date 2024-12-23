 #!/bin/bash
 chmod +x deploy-helm.sh
#  cd helm-chart/charts/ && ./deploy-helm.sh
webApiChartName="webapi"
ingressChartName="ingress" 
webappChartName="webapp"
secretProviderChartName="secrets"
NAMESPACE="ingress-nginx"
RESOURCE_GROUP_NAME="RG-AKS-INGRESS-TLS"
RESOURCE_GROUP_LOCATION="westus"
CLUSTER_NAME="aks-ingress-tls"
INGRESS_NAME="ingress-datasynchro"
CLUSTER_NAME="aks-ingress-tls"

TENANT_ID="f12a747a-cddf-4426-96ff-ebe055e215a3"
echo -e "\e[32mGetting the user-assigned identity ID for the Azure Key Vault provider for Secrets Store CSI Driver..." 

AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID=$(az identity show \
  --resource-group "MC_${RESOURCE_GROUP_NAME}_${CLUSTER_NAME}_${RESOURCE_GROUP_LOCATION}" \
  --name "azurekeyvaultsecretsprovider-${CLUSTER_NAME}" \
  --query 'clientId' \
  --output tsv)

echo -e "\e[32mUser-assigned identity ID: $AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID" 

az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl get deployments --all-namespaces=true
# az network vnet check-ip-address --name $VNET_NAME -g $RESOURCE_GROUP_NAME --ip-address $PRIVATE_IP
echo -e "\e[32mVerify the Azure Key Vault provider for Secrets Store CSI Driver installation...\e[0m"

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

echo -e "\e[32mDeploying Secret provider chart..." 
kubectl create namespace $NAMESPACE
helm upgrade --install secrets-provider $secretProviderChartName  --set tenantId=$TENANT_ID  --set userAssignedIdentityID=$AZURE_KEYVAULT_SECRETS_PROVIDER_USER_ASSIGNED_IDENTITYID


echo -e "\e[32mgetting the Azure Key Vault secret provider class..."

kubectl get SecretProviderClass -n $NAMESPACE 

# Add the ingress-nginx Helm repository if not already added
echo -e "\e[32mAdding the ingress-nginx repository..." 
 # Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update the Helm repo to ensure we have the latest charts
helm repo update

echo -e "\e[32mDeploying the NGINX ingress controller..." 
# Deploy the NGINX ingress controller with an external load balancer

    # helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    # --namespace $NAMESPACE \
    # --create-namespace \
    # --set controller.nodeSelector."kubernetes\.io/os"=linux \
    # --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    # --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz  \
    # -f extra-volumes.yaml

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace $NAMESPACE \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    -f - <<EOF
controller:
  extraVolumes:
      - name: secrets-store-inline
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "azure-tls"
  extraVolumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
EOF

ServiceName="ingress-nginx-controller"

echo -e "\e[32mWaiting for external IP for service '$ServiceName' in namespace '$NAMESPACE'..." 

externalIP=""
while [ -z "$externalIP" ]; do
    externalIP=$(kubectl get service "$ServiceName" --namespace "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$externalIP" ]; then
        echo -e "\e[32mExternal IP is still pending. Retrying in 5 seconds...\e[0m"
        sleep 5
    fi
done

echo -e "\e[32mService is ready! External IP: $externalIP" 

kubectl get secret -n $NAMESPACE

#Check the status of the pods to see if the ingress controller is online.
kubectl get pods --namespace ingress-nginx

#Now let's check to see if the service is online. This of type LoadBalancer, so do you have an EXTERNAL-IP?
kubectl get services --namespace ingress-nginx

echo -e "\e[32mDeploying web api chart..." 

helm upgrade --install datasynchro-api $webApiChartName 

echo -e "\e[32mDeploying web app chart..." 

helm upgrade --install datasynchro-app $webappChartName 

echo -e "\e[32mWaiting for the logcorner-command pod to be ready... " 

kubectl wait --for=condition=ready pod -l app=datasynchro-api-http-api --timeout=300s
kubectl wait --for=condition=ready pod -l app=datasynchro-app-http-app --timeout=300s

kubectl get pods --namespace  $NAMESPACE


echo -e "\e[32mDeploying Ingress chart..." 

helm upgrade --install ingress $ingressChartName 

kubectl describe ingressclasses nginx
kubectl get services --namespace ingress-nginx
kubectl describe ingress $INGRESS_NAME --namespace ingress-nginx
echo "Checking Ingress is ready! External IP: $externalIP"
ping  $externalIP
curl -v -k --resolve query.cloud-devops-craft.com:443:${externalIP} https://query.cloud-devops-craft.com


#  echo -e "\e[32mDeploying web api chart..." 

# helm upgrade --install datasynchro-api $webApiChartName 

# echo -e "\e[32mDeploying web app chart..." 

# helm upgrade --install datasynchro-app $webappChartName 

# echo -e "\e[32mWaiting for the logcorner-command pod to be ready... " 

# kubectl wait --for=condition=ready pod -l app=datasynchro-api-http-api --timeout=300s
# kubectl wait --for=condition=ready pod -l app=datasynchro-app-http-app --timeout=300s

# kubectl get pods --namespace  $WORKLOAD_NAMESPACE




# kubectl describe ingressclasses nginx
# kubectl get services --namespace ingress-nginx
# kubectl describe ingress $INGRESS_NAME

# echo -e "\e[32mCalling web app ... " 

# curl -v -k --resolve query.cloud-devops-craft.com:443:${externalIP} https://query.cloud-devops-craft.com


# echo -e "\e[32mCalling web api  for all weatherforecast ... " 
# curl -v http://$externalIP/api/weatherforecast -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" }

# echo -e "\e[32mCalling web api  for weatherforecast by id ... " 

# curl -v http://$externalIP/api/weatherforecast/1 -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" }

# echo -e "\e[32mCalling web api  for creating weatherforecast  ... " 

# Invoke-RestMethod -Uri "http://$externalIP/api/weatherforecast" `
#   -Method POST `
#   -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" } `
#   -ContentType "application/json" `
#   -Body '{
#     "Date": "2024-12-19",
#     "TemperatureC": 22,
#     "Summary": "Warm"
#   }'

# echo -e "\e[32mCalling web api  for updating weatherforecast ... " 

# Invoke-RestMethod -Uri "http://$externalIP/api/weatherforecast" `
#   -Method PUT `
#   -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" } `
#   -ContentType "application/json" `
#   -Body '{
#     "Date": "2024-12-19",
#     "TemperatureC": 22,
#     "Summary": "Warm"
#   }'

# echo -e "\e[32mCalling web api  for deleting weatherforecast ... " 

# Invoke-RestMethod -Uri "http://$externalIP/api/weatherforecast/1" `
#   -Method DELETE `
#   -Headers @{ "Host" = "api.ingress.cloud-devops-craft.com" } 
  
  


#  #>