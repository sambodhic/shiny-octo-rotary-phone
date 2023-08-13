resource "azurerm_service_plan" "kai" {
  name                = "kai"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "S1"
  worker_count        = 3
}

resource "azurerm_linux_web_app" "kaifrontend" {
  name                = "kaifrontend"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.kai.id

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  site_config {
    application_stack {
      # docker_image_name   = "kaidev.azurecr.io/app:latest"
      docker_image_name   = "nginx:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }
}

resource "azurerm_linux_web_app" "kaibackend" {
  name                = "kaibackend"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.kai.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }
}
