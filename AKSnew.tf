# Configure the Azure Provider
provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.0.0"
  features {}
}
resource "azurerm_resource_group" "QA-RG" {
  name     = "QA-RG"
  location = "East US 2"
}

resource "azurerm_databricks_workspace" "QA-RG" {
  name                = "databricks-QA"
  resource_group_name = azurerm_resource_group.QA-RG.name
  location            = azurerm_resource_group.QA-RG.location
  sku                 = "standard"
}

resource "azurerm_public_ip" "outbound" {
  name                = "aks-outbound-pip"
  location            = azurerm_resource_group.QA-RG.location
  resource_group_name = azurerm_resource_group.QA-RG.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = azurerm_resource_group.QA-RG.location
  name                = "aks"
  resource_group_name = azurerm_resource_group.QA-RG.name
  dns_prefix = "tf-test-loadbalancer-profile"
  kubernetes_version  = "1.16.9"
  role_based_access_control {
    enabled = true
  }

default_node_pool {
    availability_zones    = []
    enable_auto_scaling   = false
    enable_node_public_ip = false
    max_pods              = 110
    node_count            = 1
    name                  = "nodepool1"
    os_disk_size_gb       = 100
    type                  = "VirtualMachineScaleSets"
    vm_size               = "Standard_DS2_v2"
    node_taints           = []
  }

service_principal {
    client_id     = "6eb1e81a-dfae-4896-84c1-6534e17408b4"
    client_secret = "5>d!_9WDr3&XADv_*dtta.,C0-\"F*fhy"
  }
network_profile {
    load_balancer_sku  = "Standard"
    load_balancer_profile {
         managed_outbound_ip_count = 2
    }
    dns_service_ip     = "10.80.0.6"
    docker_bridge_cidr = "172.17.0.1/16"
    network_plugin     = "kubenet"
    pod_cidr           = "10.80.0.0/16"
    service_cidr       = "10.80.0.0/16"
  }
}

 resource "azurerm_storage_account" "QA-RG" {
  name                     = "dlsst"
  resource_group_name      = azurerm_resource_group.QA-RG.name
  location                 = azurerm_resource_group.QA-RG.location
  account_tier             = "Standard"
  account_replication_type = "RA-GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_network_security_group" "QA-RG" {
  name                = "QA-NSG"
  location            = azurerm_resource_group.QA-RG.location
  resource_group_name = azurerm_resource_group.QA-RG.name
}

 

resource "azurerm_network_ddos_protection_plan" "QA-RG" {
  name                = "ddospplan"
  location            = azurerm_resource_group.QA-RG.location
  resource_group_name =  azurerm_resource_group.QA-RG.name
}

 

resource "azurerm_virtual_network" "QA-RG" {
  name                = "QA-Vnet-Parata"
  location            = azurerm_resource_group.QA-RG.location
  resource_group_name = azurerm_resource_group.QA-RG.name
  address_space       = ["10.80.0.0/16"]
  dns_servers         = ["10.80.0.4", "10.80.0.5"]

 

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.QA-RG.id
    enable = true
  }

 

  subnet {
    name           = "databricks-subnet"
    address_prefix = "10.80.0.0/24"
  }

 

  subnet {
    name           = "Datalake-subnet"
    address_prefix = "10.80.1.0/24"
  }
  subnet {
    name           = "Datafactory-subnet"
    address_prefix = "10.80.2.0/24"
  }

 

  subnet {
    name           = "DWH-subnet"
    address_prefix = "10.80.3.0/24"
  }

 

    subnet {
    name           = "AKS-subnet"
    address_prefix = "10.80.4.0/24"
     security_group = azurerm_network_security_group.QA-RG.id
  }

 

 

  tags = {
    Environment = "QA"
  }
}
 