resource "azurerm_virtual_network" "spoke_vnet" {
  for_each            = var.spoke_vnets_configuration
  name                = "${local.prefix_kebap}-spoke-${each.key}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = each.value.vnet_cidr
  dns_servers         = [cidrhost(azurerm_subnet.hub_dns_subnet.address_prefix, 4)]
}

resource "azurerm_subnet" "spoke_subnet_default" {
  for_each                  = var.spoke_vnets_configuration
  name                      = "${each.key}-subnet"
  resource_group_name       = azurerm_resource_group.rg.name
  address_prefix            = each.value.subnet
  virtual_network_name      = azurerm_virtual_network.spoke_vnet[each.key].name
  network_security_group_id = azurerm_network_security_group.spoke_nsg.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke_subnet_to_spoke_nsg" {
  for_each                  = var.spoke_vnets_configuration
  subnet_id                 = azurerm_subnet.spoke_subnet_default[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke_nsg.id
}

resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "${local.prefix_kebap}-spokes-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Outbound_Allow_VirtualNetwork"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Outbound_Deny_All"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_private_dns_zone" "spoke_private_dns_zone" {
  for_each            = var.spoke_vnets_configuration
  name                = "${each.key}.${var.azure_private_dns_domain}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  for_each              = var.spoke_vnets_configuration
  name                  = "${each.key}-spoke-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.spoke_private_dns_zone[each.key].name
  virtual_network_id    = azurerm_virtual_network.spoke_vnet[each.key].id

  // Auto register VMs
  registration_enabled = true
}
