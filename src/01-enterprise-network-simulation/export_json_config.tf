locals {
  spoke_ids = [ for k in keys(var.spoke_vnets_configuration): azurerm_virtual_network.spoke_vnet[k].id ]
  spoke_names = [ for k in keys(var.spoke_vnets_configuration): azurerm_virtual_network.spoke_vnet[k].name ]
  spoke_default_subnet_ids = [ for k in keys(var.spoke_vnets_configuration): azurerm_subnet.spoke_subnet_default[k].id ]
}

data "template_file" "config_export_template" {
  template = <<__JSON__
  {
    "on_premise_vnet_id": "${azurerm_virtual_network.on_premise_vnet.id}",
    "on_premise_vnet_name": "${azurerm_virtual_network.on_premise_vnet.name}",
    "on_premise_resource_group_name": "${azurerm_resource_group.rg.name}",
    "on_premise_resource_group_location": "${azurerm_resource_group.rg.location}",
    "vdc_hub_vnet_id": "${azurerm_virtual_network.hub_vnet.id}",
    "vdc_hub_vnet_name": "${azurerm_virtual_network.hub_vnet.name}",
    "vdc_hub_resource_group_name": "${azurerm_resource_group.rg.name}",
    "vdc_hub_resource_group_location": "${azurerm_resource_group.rg.location}",
    "spokes_vnet_id": [${join(",", formatlist("\"%s\"", local.spoke_ids))}],
    "spokes_vnet_name": [${join(",", formatlist("\"%s\"", local.spoke_names))}],
    "spokes_default_subnet_id": [${join(",", formatlist("\"%s\"", local.spoke_default_subnet_ids))}],
    "spokes_resource_group_name": "${azurerm_resource_group.rg.name}",
    "spokes_resource_group_location": "${azurerm_resource_group.rg.location}"
  }
__JSON__
}

resource "local_file" "config_export_file" {
  content  = data.template_file.config_export_template.rendered
  filename = "${path.module}/${local.prefix_kebap}-config.json"
}

resource "azurerm_storage_account" "config_export_storage" {
  name                      = "${local.prefix_flat}config${local.hash_suffix}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_blob_encryption    = true
  enable_file_encryption    = true
  enable_https_traffic_only = true

  account_kind = "StorageV2"
  access_tier  = "Hot"
}

resource "azurerm_storage_container" "config_export_container" {
  name                  = "configs"
  storage_account_name  = azurerm_storage_account.config_export_storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "config_export_blob" {
  name                   = "${local.prefix_kebap}-config.json"
  storage_account_name   = azurerm_storage_account.config_export_storage.name
  storage_container_name = azurerm_storage_container.config_export_container.name
  type                   = "block"
  source                 = local_file.config_export_file.filename
  content_type           = "application/json"
}

