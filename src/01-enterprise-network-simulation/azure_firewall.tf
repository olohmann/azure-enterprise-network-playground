resource "azurerm_public_ip" "firewall_pip" {
  name                = "${local.prefix_kebap}-firewall-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "${local.prefix_kebap}-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_azure_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_route_table" "firewall_route" {
  name                = "${local.prefix_kebap}-firewall-route"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "firewall_route_table_association" {
  for_each       = var.spoke_vnets_configuration
  subnet_id      = azurerm_subnet.spoke_subnet_default[each.key].id
  route_table_id = azurerm_route_table.firewall_route.id
}

resource "azurerm_subnet_route_table_association" "firewall_route_table_association_dns" {
  subnet_id      = azurerm_subnet.hub_dns_subnet.id
  route_table_id = azurerm_route_table.firewall_route.id
}

resource "azurerm_subnet_route_table_association" "firewall_route_table_association_azure_private_dns_forwarder" {
  subnet_id      = azurerm_subnet.hub_private_azure_dns_forwarder_subnet.id
  route_table_id = azurerm_route_table.firewall_route.id
}

/* Firewall Rules */
resource "azurerm_firewall_application_rule_collection" "fw_rules_http" {
  name                = "firewall-rules-http"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_firewall.firewall.resource_group_name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "microsoft-common"

    source_addresses = ["10.0.0.0/8"]

    target_fqdns = [
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com"
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name = "canonical-ubuntu-update"

    source_addresses = ["10.0.0.0/8"]

    target_fqdns = [
      "security.ubuntu.com",
      "azure.archive.ubuntu.com",
      "changelogs.ubuntu.com"
    ]

    protocol {
      port = 80
      type = "Http"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "fw_rules_udp_ntp" {
  name                = "firewall-rules-ntp"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_firewall.firewall.resource_group_name
  priority            = 1500
  action              = "Allow"

  rule {
    name = "ntp-ubuntu"

    source_addresses = ["10.0.0.0/8"]

    destination_ports = [
      "123"
    ]

    destination_addresses = [
      "91.189.89.199",
      "91.189.89.198",
      "91.189.94.4",
      "91.189.91.157"
    ]

    protocols = [
      "UDP"
    ]
  }
}
