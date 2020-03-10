resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${local.prefix_kebap}-hub-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.hub_vnet_configuration.config.address_space
}

// No NSGs -> Azure VPN GW managed, see https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal#VNetGateway
// [...] avoid associating a network security group (NSG) to the gateway subnet. [...]
resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = var.hub_vnet_configuration.config.gateway_subnet
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}

// No NSGs -> Azure Firewall managed, see https://docs.microsoft.com/en-us/azure/firewall/firewall-faq#are-network-security-groups-nsgs-supported-on-the-azure-firewall-subnet
resource "azurerm_subnet" "hub_azure_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = var.hub_vnet_configuration.config.nva_subnet
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}

resource "azurerm_subnet" "hub_dns_subnet" {
  name                      = "dns_subnet"
  resource_group_name       = azurerm_resource_group.rg.name
  address_prefix            = var.hub_vnet_configuration.config.dns_subnet
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  network_security_group_id = azurerm_network_security_group.hub_nsg.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_subnet" "hub_private_azure_dns_forwarder_subnet" {
  name                 = "private_azure_dns_forwarder_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = var.hub_vnet_configuration.config.private_azure_dns_forwarder_subnet
  virtual_network_name = azurerm_virtual_network.hub_vnet.name

  network_security_group_id = azurerm_network_security_group.hub_nsg.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_subnet_network_security_group_association" "hub_dns_subnet_to_hub_nsg" {
  subnet_id                 = azurerm_subnet.hub_dns_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub_azure_private_dns_forwarder_subnet_to_hub_nsg" {
  subnet_id                 = azurerm_subnet.hub_private_azure_dns_forwarder_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

resource "azurerm_network_security_group" "hub_nsg" {
  name                = "${local.prefix_kebap}-hub-nsg"
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
