resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${local.prefix_kebap}-hub-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.hub_vnet_configuration.config.address_space
}

resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = var.hub_vnet_configuration.config.gateway_subnet
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}

resource "azurerm_subnet" "hub_nva_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = var.hub_vnet_configuration.config.nva_subnet
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}
