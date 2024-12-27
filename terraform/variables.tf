variable "resource_group_name" {
  type        = string
  default     = "RG-AKS-INGRESS-TLS"
  description = "Location of the azure resource group."
}
variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the azure resource group."
}


variable "user_assigned_identity_name" {
  type        = string
  default     = "aks-ingress-tls_umi"
  description = "The name of the user assigned identity."

}

#---------------   azure kubernetes services ----------------------------------------
variable "aks_name" {
  type        = string
  default     = "aks-ingress-tls"
  description = "Location of the azure resource group."
}

variable "node_count" {
  type        = string
  default     = "3"
  description = "The number of K8S nodes to provision."
}

variable "load_balancer_sku" {
  type        = string
  default     = "standard"
  description = "value for load balancer sku"
}

variable "vm_size" {
  default     = "Standard_D2_v2"
  description = "value for vm size"
}
variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "acr_name" {
  type        = string
  default     = "aksingrestlsacr"
  description = "value for acr name"
}

variable "sku" {
  type        = string
  default     = "Standard"
  description = "value for acr sku"

}

variable "key_vault_name" {
  type        = string
  default     = "kv-shared-edusync-dev"
  description = "value for key vault name"

}

variable "admin_user_object_id" {
  type        = string
  description = "The object id of the admin user."
}