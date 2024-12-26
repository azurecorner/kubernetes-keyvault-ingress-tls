
data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "azurekeyvaultsecretsprovider_assigned_identity" {
  name                = "azurekeyvaultsecretsprovider-${var.aks_name}"
  resource_group_name = "MC_${var.resource_group_name}_${var.aks_name}_${var.resource_group_location}"
  depends_on          = [azurerm_kubernetes_cluster.aks]
}
