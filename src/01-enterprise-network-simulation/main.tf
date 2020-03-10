locals {
  prefix_kebap         = lower("${var.prefix}-${terraform.workspace}")
  prefix_snake         = lower("${var.prefix}_${terraform.workspace}")
  prefix_flat          = lower("${var.prefix}${terraform.workspace}")
  location             = lower(replace(var.location, " ", ""))
  hash_suffix          = substr(sha256(azurerm_resource_group.rg.id), 0, 6)
  public_ssh_key_admin = var.public_ssh_key_admin == "" ? file("~/.ssh/id_rsa.pub") : var.public_ssh_key_admin
}

data "azurerm_client_config" "current" {
}
