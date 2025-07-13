provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "PoE-Test" {
  name     = "PoE-Test"
  location = "Uk South"
}

resource "azurerm_storage_account" "poestorageaccount" {
  name                     = "poestorageaccount"
  resource_group_name      = azurerm_resource_group.PoE-Test.name
  location                 = azurerm_resource_group.PoE-Test.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "PoE-ServicePlan" {
  name                = "PoE-ServicePlan"
  location            = azurerm_resource_group.PoE-Test.location
  resource_group_name = azurerm_resource_group.PoE-Test.name
  kind                = "FunctionApp"
  sku {
    tier = "Basic"
    size = "B1"
  }
}


resource "azurerm_function_app" "PoE-Funcs-Test" {
  name                       = "PoE-Funcs-Test"
  location                   = azurerm_resource_group.PoE-Test.location
  resource_group_name        = azurerm_resource_group.PoE-Test.name
  app_service_plan_id        = azurerm_app_service_plan.PoE-ServicePlan.id
  storage_account_name       = azurerm_storage_account.poestorageaccount.name
  storage_account_access_key = azurerm_storage_account.poestorageaccount.primary_access_key

  os_type = "linux"

  site_config {
  }
}
