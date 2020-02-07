resource "azurerm_storage_account" "scripts_storage" {
  name                      = "${local.prefix_flat}scripts${local.hash_suffix}"
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

resource "azurerm_storage_container" "scripts_container" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.scripts_storage.name
  container_access_type = "blob"
}
