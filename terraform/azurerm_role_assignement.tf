
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.container_registry]
}

resource "azurerm_role_assignment" "azurekeyvaultsecretsprovider_assigned_identity" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_user_assigned_identity.azurekeyvaultsecretsprovider_assigned_identity.principal_id
  depends_on           = [azurerm_key_vault.key_vault]
}