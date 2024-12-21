
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location

}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]

  depends_on = [azapi_resource.ssh_public_key]
}

resource "azapi_resource" "ssh_public_key" {
  type       = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name       = random_pet.ssh_key_name.id
  location   = var.resource_group_location
  parent_id  = azurerm_resource_group.resource_group.id
  depends_on = [azurerm_resource_group.resource_group]
}

output "key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
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

resource "azurerm_container_registry" "container_registry" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = var.sku
  admin_enabled       = true
  depends_on          = [azurerm_resource_group.resource_group]
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.container_registry]
}

resource "azurerm_key_vault" "key_vault" {
  name                       = "kv-shared-edusync-dev"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  depends_on = [ azurerm_resource_group.resource_group ]
}

resource "azurerm_key_vault_access_policy" "vault_access_policy_me" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "7abf4c5b-9638-4ec4-b830-ede0a8031b25"

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Restore", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Recover", "Delete", "Purge"
  ]
}