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

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
  }
}

resource "azurerm_kubernetes_cluster" "PoEk8Test" {
  name                = "poe-aks-test"
  location            = azurerm_resource_group.PoE-Test.location
  resource_group_name = azurerm_resource_group.PoE-Test.name
  dns_prefix          = "poetestaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.PoEk8Test.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.PoEk8Test.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.PoEk8Test.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.PoEk8Test.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "PoE" {
  metadata {
    name = "poe"
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.PoE.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.PoE.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          image = "redis:latest"
          name  = "redis"

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

