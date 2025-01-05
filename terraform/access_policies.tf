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