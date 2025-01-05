# kubernetes-nginx-ingress-tls

terraform init 

terraform plan -out main.tfplan

terraform apply main.tfplan 

terraform apply--auto-approve


# default     = "7abf4c5b-9638-4ec4-b830-ede0a8031b25"


 kubectl port-forward pod/datasynchro-api-http-api-deployment-6f756c67d7-jqbdj 8081:8080
http://localhost:8080/api/WeatherForecast


 kubectl port-forward pod/datasynchro-app-http-app-deployment-d4888f45c-6l7q5 8082:8080
 http://localhost:8082/

kubectl exec busybox-certificate-store-inline-user-msi -- cat /mnt/certificate-store/logcorner-datasync-cert
kubectl exec busybox-certificate-store-inline-user-msi -- cat /mnt/certificate-store/logcorner-datasync-cert.crt
kubectl exec busybox-certificate-store-inline-user-msi -- cat /mnt/certificate-store/logcorner-datasync-cert.key


https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access?tabs=azure-portal&pivots=access-with-a-user-assigned-managed-identity
https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls
https://medium.com/hedgus/azure-key-vault-provider-for-secrets-store-csi-driver-in-an-azure-kubernetes-service-aks-56de3fe6c9b4

# Using Nginx Ingress Controller and Cert-Manager for HTTPS with Let’s Encrypt ==> 

https://dev.to/hkhelil/using-nginx-ingress-controller-and-cert-manager-for-https-with-lets-encrypt-2flh