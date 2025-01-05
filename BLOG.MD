# Terraform Configuration for Azure Resources

This repository contains a Terraform configuration to provision Azure resources including an AKS cluster, an Azure Container Registry, and a Key Vault. The configuration also handles SSH key generation and DNS prefix creation dynamically.

## Resources Provisioned

### 1. **Resource Group**
A resource group is created in the specified Azure region.

```hcl
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

### 2. **Dynamic Resource Naming and SSH Key Generation**

This section of the Terraform configuration dynamically generates names for resources and securely creates an SSH public-private key pair.

#### Random Pets for Naming

- **DNS Prefix**: The `random_pet` resource generates a unique, random prefix for the Kubernetes cluster DNS name. This ensures that the DNS name is unique and prevents naming conflicts.

```hcl
resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}
