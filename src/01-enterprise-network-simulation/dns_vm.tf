resource "azurerm_network_interface" "dns_nic" {
  name                      = "${local.prefix_kebap}-${var.dns_vm_name}-nic"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.prefix_kebap}-${var.dns_vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.hub_dns_subnet.id

    // Static Private IP
    private_ip_address_allocation = "static"
    private_ip_address            = cidrhost(azurerm_subnet.hub_dns_subnet.address_prefix, 4)
  }
}

resource "azurerm_virtual_machine" "dns_vm" {
  name                  = "${local.prefix_kebap}-${var.dns_vm_name}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.dns_nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.prefix_kebap}-${var.dns_vm_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "256"
  }

  os_profile {
    computer_name  = var.dns_vm_name
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = local.public_ssh_key_admin
    }
  }
}
