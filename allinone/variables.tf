variable "backend_address_pool_name" {
    default = "kaiBackendPool"
}

variable "frontend_port_name" {
    default = "kaiFrontendPort"
}

variable "frontend_ip_configuration_name" {
    default = "kaiAGIPConfig"
}

variable "http_setting_name" {
    default = "kaiHTTPsetting"
}

variable "listener_name" {
    default = "kaiListener"
}

variable "request_routing_rule_name" {
    default = "kaiRoutingRule"
}

variable "database_name_prefix" {
  default     = "kai-postgresqlfs"
  description = "Prefix of the resource name."
}

variable "resource_group_location" {
  type        = string
  default     = "westus3"
  description = "Location for all resources."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "kai"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "Azure Storage account type."
  validation {
    condition     = contains(["Premium_LRS", "Premium_ZRS", "Standard_GRS", "Standard_GZRS", "Standard_LRS", "Standard_RAGRS", "Standard_RAGZRS", "Standard_ZRS"], var.storage_account_type)
    error_message = "Invalid storage account type. The value should be one of the following: 'Premium_LRS','Premium_ZRS','Standard_GRS','Standard_GZRS','Standard_LRS','Standard_RAGRS','Standard_RAGZRS','Standard_ZRS'."
  }
}

variable "vault_name" {
  type        = string
  description = "The name of the key vault to be created. The value will be randomly generated if blank."
  default     = ""
}

variable "key_name" {
  type        = string
  description = "The name of the key to be created. The value will be randomly generated if blank."
  default     = ""
}

variable "sku_name" {
  type        = string
  description = "The SKU of the vault to be created."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be one of the following: standard, premium."
  }
}

variable "key_permissions" {
  type        = list(string)
  description = "List of key permissions."
  default     = ["List", "Create", "Delete", "Get", "Purge", "Recover", "Update", "GetRotationPolicy", "SetRotationPolicy"]
}

variable "secret_permissions" {
  type        = list(string)
  description = "List of secret permissions."
  default     = ["Set"]
}

variable "key_type" {
  description = "The JsonWebKeyType of the key to be created."
  default     = "RSA"
  type        = string
  validation {
    condition     = contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], var.key_type)
    error_message = "The key_type must be one of the following: EC, EC-HSM, RSA, RSA-HSM."
  }
}

variable "key_ops" {
  type        = list(string)
  description = "The permitted JSON web key operations of the key to be created."
  default     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

variable "key_size" {
  type        = number
  description = "The size in bits of the key to be created."
  default     = 2048
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. If this value isn't null (the default), 'data.azurerm_client_config.current.object_id' will be set to this value."
  default     = null
}