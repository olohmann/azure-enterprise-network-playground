resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = var.spoke_vnets_configuration
  name                      = "${local.prefix_kebap}-hub-to-spoke-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet[each.key].id

  allow_forwarded_traffic      = true
  allow_virtual_network_access = true

  allow_gateway_transit = true
  use_remote_gateways   = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = var.spoke_vnets_configuration
  name                      = "${local.prefix_kebap}-spoke-${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_forwarded_traffic      = true
  allow_virtual_network_access = true

  allow_gateway_transit = false
  use_remote_gateways   = true

  // Let peering from hub->spoke first finish, then hand-shake spoke->hub.
  depends_on = [azurerm_virtual_network_peering.hub_to_spoke]
}
