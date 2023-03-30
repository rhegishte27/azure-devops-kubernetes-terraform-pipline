resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group}_${var.environment}"
  location = var.location
}

provider "azurerm" {
  version = "~>2.0.0"
  features {}
}


resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.example.kube_config_raw

  sensitive = true
}

terraform {
  backend "azurerm" {
    # storage_account_name="<<storage_account_name>>" #OVERRIDE in TERRAFORM init
    # access_key="<<storage_account_key>>" #OVERRIDE in TERRAFORM init
    # key="<<env_name.k8s.tfstate>>" #OVERRIDE in TERRAFORM init
    # container_name="<<storage_account_container_name>>" #OVERRIDE in TERRAFORM init
  }
}
