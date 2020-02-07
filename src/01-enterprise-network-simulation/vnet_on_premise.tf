resource "azurerm_virtual_network" "on_premise_vnet" {
  name                = "${local.prefix_kebap}-on-premise-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "on_premise_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = "10.0.0.0/24"
  virtual_network_name = azurerm_virtual_network.on_premise_vnet.name
}

resource "azurerm_subnet" "on_premise_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = "10.0.1.0/24"
  virtual_network_name = azurerm_virtual_network.on_premise_vnet.name
}

resource "azurerm_subnet" "on_premise_proxy_subnet" {
  name                 = "proxy-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = "10.0.2.0/24"
  virtual_network_name = azurerm_virtual_network.on_premise_vnet.name
}

resource "azurerm_subnet" "on_premise_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = "10.0.15.0/24"
  virtual_network_name = azurerm_virtual_network.on_premise_vnet.name
}
