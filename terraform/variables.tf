variable "resource_group_name" {
  type        = string
  default     = "RG-AKS-INGRESS-TLS"
  description = "Location of the azure resource group."
}
variable "resource_group_location" {
  type        = string
  default     = "westeurope"
  description = "Location of the azure resource group."
}


variable "user_assigned_identity_name" {
  type        = string
  default     = "aks-ingress-tls_umi"
  description = "The name of the user assigned identity."

}

# variable "service_principal_name" {
#   type        = string
#   description = "The name of the service principal."

# }

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
  default = "standard"
}

variable "vm_size" {
  default = "Standard_D2_v2"
}
variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "acr_name" {
  default = "aksingrestlsacr"
}

variable "sku" {
  default = "Standard"

}