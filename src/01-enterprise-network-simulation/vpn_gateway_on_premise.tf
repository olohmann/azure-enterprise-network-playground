resource "azurerm_public_ip" "vpn_gw_on_prem_pip" {
  name                = "${local.prefix_kebap}-vpn-gw-on-prem-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vpn_gw_on_prem" {
  name                = "${local.prefix_kebap}-vpn-gw-on-prem"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw_on_prem_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.on_premise_gateway_subnet.id
  }
}
