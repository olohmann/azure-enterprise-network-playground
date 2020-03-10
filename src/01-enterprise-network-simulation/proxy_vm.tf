resource "azurerm_public_ip" "proxy_pip" {
  name                = "${local.prefix_kebap}-proxy-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

resource "azurerm_network_interface" "proxy_nic" {
  name                      = "${local.prefix_kebap}-${var.proxy_server_name}-nic"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.proxy_nsg.id

  ip_configuration {
    name                          = "${local.prefix_kebap}-${var.proxy_server_name}-ipconfig"
    subnet_id                     = azurerm_subnet.on_premise_proxy_subnet.id
    public_ip_address_id          = azurerm_public_ip.proxy_pip.id

    // Static Private IP
    private_ip_address_allocation = "static"
    private_ip_address            = cidrhost(azurerm_subnet.on_premise_proxy_subnet.address_prefix, 4)
  }
}

resource "azurerm_network_security_group" "proxy_nsg" {
  name                = "${local.prefix_kebap}-${var.proxy_server_name}-nsg"
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
    name                       = "Outbound_Allow_Internet_80"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Outbound_Allow_Internet_443"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
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

resource "azurerm_virtual_machine" "proxy_vm" {
  name                  = "${local.prefix_kebap}-${var.proxy_server_name}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.proxy_nic.id]
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
    name              = "${local.prefix_kebap}-${var.proxy_server_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "256"
  }

  os_profile {
    computer_name  = var.proxy_server_name
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
