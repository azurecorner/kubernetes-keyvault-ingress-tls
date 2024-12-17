$ChartName = "webapi"
$IMAGE_TAG = "1217"
$NAMESPACE = "ingress-nginx"
$RESOURCE_GROUP_NAME = "RG-AKS-INGRESS-TLS"
$CLUSTER_NAME = "aks-ingress-tls"
$WORKLOAD_NAMESPACE = "default"

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

# Deploy the NGINX ingress controller with an internal load balancer
Write-Host "Deploying the NGINX ingress controller..." -ForegroundColor Green


# Use Helm to deploy an NGINX ingress controller without static private IP address
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx  `
--namespace $NAMESPACE  `
--create-namespace  `
--set controller.service.type=LoadBalancer  `
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true" 

$ServiceName = "ingress-nginx-controller"

Write-Host "Waiting for external IP for service '$ServiceName' in namespace '$NAMESPACE'..."

do {
    $externalIP = kubectl get service $ServiceName --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if (-not $externalIP) {
        Write-Host "External IP is still pending. Retrying in 5 seconds..."
        Start-Sleep -Seconds 5
    }
} while (-not $externalIP)

Write-Host "Service is ready! External IP: $externalIP"


#Check the status of the pods to see if the ingress controller is online.
kubectl get pods --namespace ingress-nginx


#Now let's check to see if the service is online. This of type LoadBalancer, so do you have an EXTERNAL-IP?
kubectl get services --namespace ingress-nginx


#Check out the ingressclass nginx...we have not set the is-default-class so in each of our Ingresses we will need 
#specify an ingressclassname
kubectl describe ingressclasses nginx


#Deploy an additional Helm chart (logcorner-command)
Write-Host "Deploying logcorner-command chart..." -ForegroundColor Green
# Change to the correct directory (up one level)

# kubectl delete pod curl-test --namespace  helm

# $status = kubectl get pod curl-test --namespace $WORKLOAD_NAMESPACE -o jsonpath='{.status.phase}'
# if ($status -ne "Running") {
#     kubectl delete pod curl-test --namespace $WORKLOAD_NAMESPACE
# }


# helm upgrade --install logcorner-command  $ChartName
helm upgrade --install http-api $ChartName 


write-host "Waiting for the logcorner-command pod to be ready... " -ForegroundColor Green
kubectl wait --for=condition=ready pod -l app=http-api --timeout=300s

kubectl get pods --namespace  $WORKLOAD_NAMESPACE


# #We can see the host, the path, and the backends.
# kubectl describe ingress ingress-path


# $INGRESSIP=$(kubectl get ingress -o jsonpath='{ .items[].status.loadBalancer.ingress[].ip }')
# curl http://$INGRESSIP

# curl http://$INGRESSIP/red  --header 'Host: ingress.cloud-devops-craft.com'
# curl http://$INGRESSIP/blue --header 'Host: ingress.cloud-devops-craft.com'