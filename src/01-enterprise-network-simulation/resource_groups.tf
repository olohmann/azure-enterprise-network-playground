resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_snake}_enterprise_network_simulation_rg"
  location = var.location
}
