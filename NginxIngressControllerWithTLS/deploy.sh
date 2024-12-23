 #!/bin/bash
 chmod +x deploy.sh
#  cd NginxIngressControllerWithTLS/ && ./deploy.sh

az aks get-credentials --resource-group RG-AKS-INGRESS-TLS --name aks-ingress-tls --overwrite-existing

NAMESPACE=ingress-basic

kubectl create namespace $NAMESPACE

kubectl apply -f secretProviderClass.yaml -n $NAMESPACE

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


helm upgrade --install ingress-basic ingress-nginx/ingress-nginx  \
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

kubectl get secret -n $NAMESPACE

kubectl apply -f aks-helloworld-one.yaml -n $NAMESPACE
kubectl apply -f aks-helloworld-two.yaml -n $NAMESPACE

kubectl apply -f hello-world-ingress.yaml -n $NAMESPACE


EXTERNAL_IP=$(kubectl get service --namespace $NAMESPACE --selector app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
echo "Public IP: ${EXTERNAL_IP}"

kubectl apply -f pod.yaml -n $NAMESPACE

kubectl exec -n ingress-basic busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/


# curl -v -k --resolve demo.cloud-devops-craft.com:443:EXTERNAL_IP https://demo.cloud-devops-craft.com