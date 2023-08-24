data "azurerm_client_config" "current" {}

locals {
  business_lower = lower(var.business)
  env_lower     = lower(var.env)
}

resource "azurerm_resource_group" "rg" {
  name     = format("%s-%s-rg", local.business_lower, local.env_lower)
  location = var.location
  tags     = var.tags
}

resource "azurerm_app_service_plan" "plan" {
  depends_on = [azurerm_resource_group.rg]
  name                = format("%s-%s-plan", local.business_lower, local.env_lower)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Consumption"
    size = "Y1"
  }
  tags = var.tags
}

resource "azurerm_storage_account" "storage" {
  depends_on = [azurerm_resource_group.rg]
  name                     = format("%s%sstg", local.business_lower, local.env_lower)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_key_vault" "vault" {
  depends_on = [azurerm_resource_group.rg]
  name                = format("%s-%s-vault", local.business_lower, local.env_lower)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags
}

resource "azurerm_data_factory" "adf" {
  depends_on = [azurerm_resource_group.rg]
  name                = format("%s-%s-adf", local.business_lower, local.env_lower)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace" "logs" {
  depends_on = [azurerm_resource_group.rg]
  name                = format("%s-%s-logs", local.business_lower, local.env_lower)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days  = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "appi" {
  depends_on = [azurerm_resource_group.rg, azurerm_log_analytics_workspace.logs]
  name                = format("%s-%s-appi", local.business_lower, local.env_lower)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  tags                = var.tags
  workspace_id        = azurerm_log_analytics_workspace.logs.id
}

resource "azurerm_function_app" "func" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_app_service_plan.plan,
    azurerm_storage_account.storage,
    azurerm_application_insights.appi
  ]
  name                      = format("%s-%s-func", local.business_lower, local.env_lower)
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  app_service_plan_id       = azurerm_app_service_plan.plan.id
  storage_account_name      = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  tags                       = var.tags
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appi.instrumentation_key
  }
}

output "instrumentation_key" {
  value     = azurerm_application_insights.appi.instrumentation_key
  sensitive = true
}

output "app_id" {
  value     = azurerm_application_insights.appi.app_id
  sensitive = true
}
