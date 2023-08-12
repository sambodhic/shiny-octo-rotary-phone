variable "resource_group_name" {
  type    = string
  default = "kai"
}

variable "resource_group_location" {
  type    = string
  default = "westus3"
}

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

