data "azurerm_user_assigned_identity" "azurekeyvaultsecretsprovider_assigned_identity" {
  name                = "azurekeyvaultsecretsprovider-${var.aks_name}"
  resource_group_name = "MC_${var.resource_group_name}_${var.aks_name}_${var.resource_group_location}" # MC_rg-edusync-dev_aks-edusync-dev_eastus

}

resource "azurerm_role_assignment" "azurekeyvaultsecretsprovider_assigned_identity" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_user_assigned_identity.azurekeyvaultsecretsprovider_assigned_identity.principal_id

}

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

}