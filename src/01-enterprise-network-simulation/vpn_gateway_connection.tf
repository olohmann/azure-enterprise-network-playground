resource "random_string" "shared_key" {
  length  = 23
  special = false
}

resource "azurerm_virtual_network_gateway_connection" "on_prem_to_vdc" {
  name                = "${local.prefix_kebap}-on-prem-to-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpn_gw_on_prem.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw_hub.id

  shared_key = random_string.shared_key.result
}

resource "azurerm_virtual_network_gateway_connection" "vdc_to_on_prem" {
  name                = "${local.prefix_kebap}-hub-to-on-prem"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpn_gw_hub.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw_on_prem.id

  shared_key = random_string.shared_key.result
}
