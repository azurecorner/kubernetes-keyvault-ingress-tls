# Setting Up TLS for Ingress Nginx on Azure Kubernetes Service (AKS) Using Azure Key Vault

This guide explains how to set up a secure environment for a .NET Core web application (`webapp`) and a .NET Core web API (`webapi`) deployed in Azure Kubernetes Service (AKS) using an Ingress NGINX Controller with TLS certificates stored in Azure Key Vault. The entire infrastructure and application deployment is automated using Terraform and Helm.

## Key Components

1. **Applications**: 
   - `webapp`: A .NET Core web application.
   - `webapi`: A .NET Core web API.
   
2. **Infrastructure**:
   - **Azure Kubernetes Service (AKS)**: Hosts the containerized applications.
   - **Azure Container Registry (ACR)**: Stores container images for `webapp` and `webapi`.
   - **Azure Key Vault**: Securely stores the TLS certificates.
   
3. **Ingress NGINX Controller**:
   - Acts as a gateway to route external traffic to your Kubernetes services.
   - Configured to use TLS for secure communication, with certificates retrieved from Azure Key Vault.

4. **Automation**:
   - **Terraform**: Provisions and manages infrastructure (AKS, ACR, Key Vault).
   - **Helm Charts**: Deploys the applications, Ingress NGINX, and other Kubernetes resources.

## Workflow Overview

1. **Infrastructure Setup**:
   - Terraform is used to create:
     - An AKS cluster for running Kubernetes workloads.
     - An ACR to store the container images.
     - An Azure Key Vault to securely manage and store the TLS certificates.

2. **Application Deployment**:
   - Both the `webapp` and `webapi` applications are containerized and pushed to ACR.
   - Helm charts are used to deploy these applications to AKS, ensuring a consistent and repeatable deployment process.

3. **Ingress NGINX and TLS Configuration**:
   - The Ingress NGINX controller is deployed via Helm.
   - The controller is configured with an Ingress resource to route traffic to `webapp` and `webapi`.
   - TLS certificates for the domain are securely stored in Azure Key Vault.
   - Ingress NGINX retrieves these certificates to enable HTTPS for secure communication.

## Benefits of This Setup

- **Secure Communication**: TLS ensures data privacy and security between clients and your applications.
- **Scalable Deployment**: Terraform and Helm automate infrastructure provisioning and application deployment.
- **Centralized Certificate Management**: Azure Key Vault provides a secure, centralized solution for managing TLS certificates.

By leveraging Terraform, Helm, and Azure services, this setup provides a secure, scalable, and automated approach to deploying and managing your .NET Core applications in a Kubernetes environment.

# Architecture Overview
![architecture drawio](https://github.com/user-attachments/assets/10bec166-c7b8-4ee7-b73f-5a8fc4d6ad0d)

# Terraform Configuration for Azure Resources

This repository contains a Terraform configuration to provision Azure resources including an AKS cluster, an Azure Container Registry, and a Key Vault. The configuration also handles SSH key generation and DNS prefix creation dynamically.

### 1. **Resource Group**

A resource group is created in the specified Azure region.

```hcl
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}
```

### 2. **generates a random pet name using the random_pe` resource type**

This Terraform file defines a resource that generates a **random pet name** using the `random_pet` resource type. The `random_pet` resource is commonly used to generate unique, human-readable names that can be used in naming conventions for resources.

```hcl
resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}
```

### 3. **creating and managing an Azure SSH public key**

This Terraform configuration defines resources for creating and managing an Azure SSH public key using the **`azapi` provider**, which allows interacting with Azure Resource Manager (ARM) resources using API calls.
Creates the Azure SSH public key resource under the specified Resource Group and location.

```hcl
resource "azapi_resource_action" "ssh_public_key_gen" {
  type                   = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id            = azapi_resource.ssh_public_key.id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey", "privateKey"]
  depends_on             = [azapi_resource.ssh_public_key]
}

resource "azapi_resource" "ssh_public_key" {
  type       = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name       = random_pet.ssh_key_name.id
  location   = var.resource_group_location
  parent_id  = azurerm_resource_group.resource_group.id
  depends_on = [azurerm_resource_group.resource_group]
}
```

### 4. **Azure Kubernetes Service (AKS)**

This Terraform configuration deploys an **Azure Kubernetes Service (AKS)** cluster with the following key features:

- **Dynamic DNS Prefix**: A unique DNS prefix is generated for the Kubernetes API server using the `random_pet` resource.
- **System-Assigned Identity**: The AKS cluster uses a managed identity for secure interaction with other Azure resources.
- **Node Pool**: A default node pool is configured with customizable VM size and node count.
- **SSH Access**: Secure SSH access is enabled using a dynamically generated public key.
- **Networking**: Configured with the `kubenet` network plugin and a configurable load balancer SKU.
- **Key Vault Integration**: Includes a Key Vault Secrets Provider with automatic secret rotation.

This setup ensures a scalable, secure, and well-integrated Kubernetes cluster in Azure.

```hcl
resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = var.resource_group_location
  name                = var.aks_name
  resource_group_name = var.resource_group_name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = var.vm_size
    node_count = var.node_count

  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = var.load_balancer_sku
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
  depends_on = [azurerm_resource_group.resource_group]
}
```

### 5. **Azure Container Registry (ACR)**

This Terraform configuration creates an **Azure Container Registry (ACR)** with the following key features:

- **Name**: The registry name is defined by a variable for flexibility.
- **Resource Group and Location**: The registry is deployed in a specified resource group and Azure region.
- **SKU**: The SKU (e.g., Basic, Standard, or Premium) is configurable for scalability and cost optimization.
- **Admin Access**: Admin access is enabled for direct authentication and management.
- **Dependency**: Ensures the ACR is created only after the resource group is available.

This setup provides a fully functional and easily configurable container registry in Azure.

```hcl
resource "azurerm_container_registry" "container_registry" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = var.sku
  admin_enabled       = true
  depends_on          = [azurerm_resource_group.resource_group]
}
```

### 6. **Azure Key Vault**

This Terraform configuration creates an **Azure Key Vault** with the following key features:

- **Name**: The Key Vault name is defined using a variable for flexibility.
- **Resource Group and Location**: The Key Vault is deployed in a specified resource group and Azure region.
- **Tenant ID**: Tied to the Azure tenant for secure access management.
- **SKU**: Uses the "Standard" SKU for cost-effective secret and key management.
- **Soft Delete Retention**: Soft-deleted items are retained for 7 days for recovery purposes.
- **Purge Protection**: Purge protection is disabled to allow permanent deletion if needed.
- **Dependency**: Ensures the Key Vault is created only after the resource group is available.

This setup provides a secure and manageable Key Vault for storing sensitive information in Azure.

```hcl
resource "azurerm_key_vault" "key_vault" {
  name                       = var.key_vault_name
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  depends_on                 = [azurerm_resource_group.resource_group]
}
```

### 7. **role-based access control (RBAC) AcrPull**

This Terraform configuration assigns a **role-based access control (RBAC)** role to enable the Azure Kubernetes Service (AKS) cluster to pull images from the Azure Container Registry (ACR).

- **Scope**: The role assignment is scoped to the ACR resource.
- **Role Definition**: Assigns the `AcrPull` role, which grants permission to pull container images.
- **Principal ID**: Uses the `kubelet_identity` of the AKS cluster to identify the principal that requires the permission.
- **Dependencies**: Ensures that the role assignment is created only after both the AKS cluster and the ACR are available.

This configuration securely integrates AKS with ACR, allowing the cluster to pull container images as needed.

```hcl
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.container_registry]
}
```

### 8. **role-based access control (RBAC) Key Vault Certificates Officer for Key Vault Secrets Provider**

This Terraform configuration assigns a **role-based access control (RBAC)** role to a user-assigned managed identity for interacting with Azure Key Vault.

- **Scope**: The role assignment is scoped to the Azure Key Vault resource.
- **Role Definition**: Assigns the `Key Vault Certificates Officer` role, which grants permissions to manage certificates in the Key Vault.
- **Principal ID**: Specifies the principal ID of the user-assigned managed identity, retrieved from `data.azurerm_user_assigned_identity`.
- **Dependencies**: Ensures the role assignment is created only after the Key Vault is provisioned.

This setup enables secure and granular access for the managed identity to interact with Key Vault certificates.

```hcl
resource "azurerm_role_assignment" "azurekeyvaultsecretsprovider_assigned_identity" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_user_assigned_identity.azurekeyvaultsecretsprovider_assigned_identity.principal_id
  depends_on           = [azurerm_key_vault.key_vault]
}
```

### 9. **access policy for an Azure Key Vault, granting specific permissions to a user-assigned managed identity**

This Terraform configuration creates an **access policy** for an Azure Key Vault, granting specific permissions to a user-assigned managed identity.

- **Key Vault ID**: Specifies the Key Vault to which the access policy applies.
- **Tenant ID**: Associates the access policy with the Azure Active Directory (AAD) tenant.
- **Certificate Permissions**: Grants permissions for managing certificates, including `Get` and `List`.
- **Object ID**: Identifies the user-assigned managed identity that receives the permissions.
- **Secret Permissions**: Grants permissions to manage secrets, including `Get`, `List`, `Set`, and `Recover`.
- **Dependencies**: Ensures the access policy is applied only after the Key Vault and AKS cluster are provisioned.

This setup ensures secure and precise access control for the managed identity to interact with the Key Vault's secrets and certificates.

```hcl
resource "azurerm_key_vault_access_policy" "vault_access_policy_managed_id" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  certificate_permissions = [
    "Get", "List"
  ]

  object_id = data.azurerm_user_assigned_identity.azurekeyvaultsecretsprovider_assigned_identity.principal_id
  secret_permissions = [
    "Get", "List", "Set", "Recover"
  ]
  depends_on = [azurerm_key_vault.key_vault, azurerm_kubernetes_cluster.aks]
}
```

### 10. **access policy** for an Azure Key Vault, granting an administrator extensive permissions**

This Terraform configuration creates an **access policy** for an Azure Key Vault, granting an administrator extensive permissions.

- **Key Vault ID**: Specifies the Key Vault to which the access policy applies.
- **Tenant ID**: Associates the access policy with the Azure Active Directory (AAD) tenant.
- **Object ID**: Identifies the administrator user (specified via `var.admin_user_object_id`) who receives the permissions.
- **Certificate Permissions**: Grants full control over certificates, including `Get`, `List`, `Update`, `Create`, `Import`, `Delete`, `Recover`, `Restore`, and `Purge`.
- **Secret Permissions**: Provides permissions to manage secrets, including `Get`, `List`, `Set`, `Recover`, `Delete`, and `Purge`.
- **Dependencies**: Ensures the access policy is applied only after the Key Vault is provisioned.

This configuration ensures the administrator has complete access to manage certificates and secrets within the Key Vault.

```hcl
resource "azurerm_key_vault_access_policy" "vault_access_policy_me" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.admin_user_object_id

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Restore", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Recover", "Delete", "Purge"
  ]
  depends_on = [azurerm_key_vault.key_vault]
}
```

### 11. **Explanation of the Data Sources**

This Terraform configuration uses **data sources** to retrieve information about the current Azure client and a user-assigned managed identity for interacting with Azure Key Vault.

---

### 11.1. **`azurerm_client_config` "current"**

This data source retrieves information about the **current Azure client configuration**. It provides details like the Azure tenant ID, which is required for some resources and access policies.

- **Purpose**: To retrieve the current Azure tenant ID for later use in other resources (e.g., Key Vault access policies).
  
---

### 11.2. **`azurerm_user_assigned_identity` "azurekeyvaultsecretsprovider_assigned_identity"**

This data source fetches an existing **user-assigned managed identity** that will be used for interacting with Azure Key Vault.

- **`name`**: Specifies the name of the user-assigned identity, dynamically created using the AKS name.
- **`resource_group_name`**: Defines the resource group where the user-assigned identity resides, based on the AKS resource group and location.
- **`depends_on`**: Ensures the identity is only fetched after the AKS cluster has been created.

- **Purpose**: To retrieve the details of a user-assigned identity for use in access policies and role assignments.

---

These data sources enable the dynamic retrieval of the required information for securely configuring the managed identity and access policies.

```hcl
data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "azurekeyvaultsecretsprovider_assigned_identity" {
  name                = "azurekeyvaultsecretsprovider-${var.aks_name}"
  resource_group_name = "MC_${var.resource_group_name}_${var.aks_name}_${var.resource_group_location}"
  depends_on          = [azurerm_kubernetes_cluster.aks]
}
```

- **terraform init**

- **terraform plan -out main.tfplan**

- **terraform apply main.tfplan**

# Helm Chart for Deploying AKS Web API, WebApp, and Ingress Controller with TLS using Azure KeyVault

## 3. Hierarchical Summary

This structure repeats for every subdirectory under the base directory. The key directories and their notable files are:

- **`charts`**:  
  Contains `deploy-helm.ps1` and `extra-volumes.yaml`.

- **`charts/ingress`**:  
  Contains Helm configuration files like `Chart.yaml` and `values.yaml`.

- **`charts/ingress/templates`**:  
  Contains template files like `ingress-tls.yaml` and `test-pod.yaml`.

- **`charts/secrets`**:  
  Contains secret-related configuration files like `Chart.yaml` and `values.yaml`.

- **`charts/webapi` and `charts/webapp`**:  
  Contain their own `Chart.yaml`, `values.yaml`, and related templates like `web-api.yaml` and `web-app.yaml`.

  ## Helm chart configuration of secret-related  files like SecretProviderClass

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: {{ .Values.secretProviderClassName }}
  namespace: {{ .Values.namespace }}
spec:
  provider: azure
  secretObjects:                            # secretObjects defines the desired state of synced K8s secret objects
    - secretName: {{ .Values.secretName }}
      type: kubernetes.io/tls
      data: 
        - objectName: {{ .Values.objectName }}
          key: tls.key
        - objectName: {{ .Values.objectName }}
          key: tls.crt
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: {{ .Values.userAssignedIdentityID }}  # the user-assigned identity ID
    keyvaultName:  {{ .Values.keyVaultName}}          # the name of the AKV instance
    objects: |
      array:
        - |
          objectName: {{ .Values.objectName }}
          objectType: secret
    tenantId: {{ .Values.tenantId }}                    # the tenant ID of the AKV instance

```

The provided YAML manifest defines a SecretProviderClass resource for the Azure Key Vault Provider for Secrets Store CSI Driver. This enables Kubernetes pods to securely retrieve secrets stored in Azure Key Vault and sync them as Kubernetes secrets.

- **`spec.provider`**:  
  Specifies the cloud provider for the Secrets Store CSI Driver. In this case, it is set to `azure`.

- **`spec.secretObjects`**:  
  Configures how secrets are synced into Kubernetes secrets:
  - **`secretName`**: The name of the resulting Kubernetes secret.  
  - **`type`**: The type of the Kubernetes secret (`kubernetes.io/tls` in this case).  
  - **`data`**: Maps objects stored in Azure Key Vault to keys in the Kubernetes secret (e.g., `tls.key` and `tls.crt`).  

- **`parameters.objects`**:  
  Specifies the Key Vault objects to retrieve:
  - **`objectName`**: The name of the object in Azure Key Vault (templated here).  
  - **`objectType`**: The type of object in Azure Key Vault (e.g., `secret`).  

### Configuration Values and Explanation

```yaml
namespace: ingress-nginx
secretProviderClassName: azure-tls
secretName: ingress-tls-csi
objectName: logcorner-datasync-cert
keyVaultName: kv-shared-edusync-dev
userAssignedIdentityID: XXXXXXXXXXX
tenantId: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Field Explanations

- **`namespace: ingress-nginx`**  
  Specifies the Kubernetes namespace where the resources will be deployed. Here, it is set to `ingress-nginx`.

- **`secretProviderClassName: azure-tls`**  
  The name of the `SecretProviderClass` that defines the connection and retrieval configuration for Azure Key Vault secrets.

- **`secretName: ingress-tls-csi`**  
  The name of the Kubernetes secret that will store the TLS certificate data (`tls.key` and `tls.crt`) retrieved from Azure Key Vault.

- **`objectName: logcorner-datasync-cert`**  
  The name of the specific object (e.g., a certificate) stored in Azure Key Vault to be retrieved.

- **`keyVaultName: kv-shared-edusync-dev`**  
  The Azure Key Vault instance from which secrets or certificates will be accessed.

- **`userAssignedIdentityID: XXXXXXXXXXX`**  
  The ID of the **User-Assigned Managed Identity (UAMI)** used to authenticate with Azure Key Vault.

- **`tenantId: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`**  
  The Azure Active Directory (AAD) tenant ID associated with the Azure Key Vault.

## Helm chart configuration of web api

### Deployment and Service Templates for Helm Chart

This Helm chart defines Kubernetes resources for deploying an API service using a `Deployment` and a `Service`.

---

## **Template: `templates/deployment.yaml`**

### **Deployment Resource**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "aks-command-api.fullname" . }}-deployment
  namespace: {{ .Values.namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "aks-command-api.fullname" . }}
  template:
    metadata:
      labels:
        app: {{ include "aks-command-api.fullname" . }}
    spec:
      containers:
      - name: aks-command-api
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.containerPort }}
       
        env:
        - name: TITLE
          value: "{{ .Values.env.title }}"
        - name: ASPNETCORE_ENVIRONMENT
          value: "{{ .Values.env.aspnetcoreEnvironment }}"
```

- **name**: Generated dynamically using the fullname helper.
- **namespace**: Uses the namespace from values.yaml.
Spec:

- **replicas**: Number of pod replicas set dynamically using values.yaml.
- **Selector**: Matches labels with the fullname.
- **Template**:
Defines container configurations, including the image, ports, and environment variables.
- **Environment Variables**:
TITLE: A welcome message set in values.yaml.
ASPNETCORE_ENVIRONMENT: Indicates the environment (e.g., Kubernetes).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "aks-command-api.fullname" . }}-service
  namespace: {{ .Values.namespace }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}  # Expose port 80 to external access
    targetPort: {{ .Values.service.targetPort }}   # Map to port 8080 inside the pod
  selector:
    app: {{ include "aks-command-api.fullname" . }}
```

- **name**: Dynamically generated using the fullname helper.
- **namespace**: Defined in values.yaml.

- **type**: The service type (e.g., ClusterIP) is set dynamically.

- **port**: External port (default 80).
- **targetPort**: Maps to the container's port (default 8080).
- **Selector**: Matches pods labeled with the fullname.

```yaml
namespace: ingress-nginx
replicaCount: 1

image:
  repository: aksingrestlsacr.azurecr.io/kubernetes-ingress-tls-api
  pullPolicy: IfNotPresent
  tag: v1.0.0

service:
  type: ClusterIP
  port: 80
  targetPort: 8080
  containerPort: 8080

env:
  title: "Welcome to Azure Kubernetes Service (AKS)"
  aspnetcoreEnvironment: "Kubernetes"

```

- **namespace**: The namespace where resources will be deployed.
- **replicaCount**: Number of pod replicas.

#### image ####

- **repository**: The container image repository.
- **pullPolicy**: Specifies when the image should be pulled (IfNotPresent).
- **tag**: Image version (v1.0.0).

#### service ####

- **type**: Type of Kubernetes service (ClusterIP).
- **port and targetPort**: Map external and container ports.
- **containerPort**: The port exposed by the container.

#### env ####

- **title**: Sets a welcome message.
- **aspnetcoreEnvironment**: Specifies the runtime environment.

```yaml
apiVersion: v2
name: http-api
appVersion: "1.0.0"
description: A Helm chart for the API HTTP service
version: 1.0.0
type: application


```

- **apiVersion**: Helm chart API version (v2).
- **name**: The chart's name (http-api).
- **appVersion**: The version of the deployed application (1.0.0).
- **description**: Brief description of the chart.
- **version**: The Helm chart's version (1.0.0).
- **type**: The chart type (application).

## Helm chart configuration of web app

### Deployment and Service Templates for Helm Chart

The Helm configuration of the web app is similar to that of the web api, so we follow the same principle. So I will not describe it in this document.

## Helm chart configuration of ingress nginx

# Ingress Configuration for TLS (`ingress-tls.yaml`)

This template defines a Kubernetes `Ingress` resource to expose services securely using TLS. The configuration is tailored for Helm templating, allowing flexibility across environments.

---

## **Ingress Resource**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.ingressName }}
  namespace: {{ .Values.namespace }}
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - {{ .Values.hosts.webapi }}
    - {{ .Values.hosts.webapp }}
    secretName: {{ .Values.secretName }}
  rules:
  - host: {{ .Values.hosts.webapi }}
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: {{ .Values.service.webapi }}
            port:
              number: 80
  - host: {{ .Values.hosts.webapp }}
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: {{ .Values.service.webapp }}
            port:
              number: 80
```


- **name**: Set dynamically using ingressName from values.yaml.
- **namespace**: The namespace is defined in values.yaml.
 **TLS Configuration**:

**tls**:
- **hosts**: Specifies the domains for which TLS termination is enabled.
- **secretName**: References the Kubernetes secret containing the TLS certificate.
 **Ingress Rules**:

**Defines routing rules for HTTP traffic**:
- **Host**: Specifies the domain (webapi and webapp hosts) for the traffic.
- **Path**: Matches requests with a specific path (/ in this case).
**Backend**:
- **service.name**: The service name to forward traffic to.
- **port.number**: The target service port (default 80).

# Values Configuration (`values.yaml`)

This configuration file defines customizable values for the Helm chart that will deploy resources such as ingress, secrets, and services.

---

## **Namespace and Resource Names**

```yaml
namespace: ingress-nginx
ingressName: ingress-datasynchro
secretName: ingress-tls-csi
secretProviderClassName: azure-tls

hosts:
  webapp: app.cloud-devops-craft.com 
  webapi: api.cloud-devops-craft.com
 
service:
  webapp: datasynchro-app-http-app-service
  webapi: datasynchro-api-http-api-service

volume:
  name: secrets-store-inline
  mountPath: "/mnt/secrets-store"

```

### Namespace
- **namespace**: Specifies the Kubernetes namespace where resources are deployed.  
  **Example**: `ingress-nginx`

### Ingress Resource
- **ingressName**: The name of the ingress resource.  
  **Example**: `ingress-datasynchro`

### TLS Configuration
- **secretName**: Name of the Kubernetes secret used for TLS configuration.  
  **Example**: `ingress-tls-csi`

- **secretProviderClassName**: The `SecretProviderClass` for the CSI driver integration with Azure Key Vault.  
  **Example**: `azure-tls`

### Hosts Configuration


hosts:
  - **webapp**: app.cloud-devops-craft.com
  - **webapi**: api.cloud-devops-craft.com



# Deployment using powershell 
This PowerShell script automates the deployment of an AKS (Azure Kubernetes Service) cluster with an NGINX Ingress Controller, TLS certificates integration using Azure Key Vault, and deployment of .NET Core applications (webapp and webapi) along with an Ingress configuration.
# Explanation of the PowerShell Script

This script automates the setup and deployment of a Kubernetes environment in Azure, with key components like an NGINX Ingress Controller, Azure Key Vault integration, and .NET Core applications. Below is an explanation of the steps:

## 1. **Variable Initialization**
The script begins by defining variables for chart names, namespace, resource group, cluster name, and other Azure-specific identifiers.

## 2. **Cluster Authentication**
The script authenticates with the Azure Kubernetes Service (AKS) cluster using Azure CLI. This ensures the local environment has the correct credentials to interact with the cluster.

## 3. **Azure Key Vault Integration**
- Verifies the installation of the Secrets Store CSI Driver for Kubernetes.
- Retrieves the user-assigned managed identity ID used to access secrets in Azure Key Vault.
- Deploys the Key Vault Secrets Provider Helm chart, enabling seamless integration between Azure Key Vault and Kubernetes.

## 4. **Deploy NGINX Ingress Controller**
- Adds the Helm repository for NGINX and updates the Helm charts to ensure the latest versions are used.
- Deploys the NGINX Ingress Controller with a LoadBalancer service, enabling external access to applications.
- Configures health probes and ensures the controller is properly set up.

## 5. **Wait for Load Balancer External IP**
The script continuously checks for the LoadBalancer’s external IP address, which is required to route traffic to the Ingress Controller. It waits until the IP address is available.

## 6. **Validate NGINX Deployment**
- Retrieves and verifies Kubernetes services, secrets, and pods related to the NGINX Ingress Controller.
- Confirms that the services are online and accessible.

## 7. **Deploy Applications**
- Deploys the Web API and Web App using Helm charts.
- Ensures the pods are ready and operational by waiting for their readiness status.

## 8. **Deploy and Validate Ingress**
- Deploys the Ingress configuration using a Helm chart to route traffic to the deployed applications.
- Verifies the Ingress configuration, ensuring it is properly defined and functional.

## 9. **Access Applications**
- Pings the external IP address to confirm connectivity.
- Makes HTTPS requests to the deployed Web App and Web API using `curl` to validate their functionality.
- Outputs HTTP response codes and responses for verification.

## 10. **Summary**
This script ensures a fully automated, secure deployment of Kubernetes infrastructure and applications with:
- Secure TLS via Azure Key Vault.
- Traffic routing via NGINX Ingress.
- Automated validation to confirm successful deployment.

