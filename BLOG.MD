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

# Helm Chart Configuration for Deployment in azure

# Deployment using powershell 