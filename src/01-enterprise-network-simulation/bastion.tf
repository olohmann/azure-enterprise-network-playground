data "template_file" "init_script" {
  template = <<__SCRIPT__
#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt -yq install software-properties-common

sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt -yq install ansible
__SCRIPT__
}

resource "local_file" "bastion_init_script" {
  content  = data.template_file.init_script.rendered
  filename = "${path.module}/${local.prefix_kebap}-bastion-init.sh"
}

resource "azurerm_storage_blob" "vm_init_script_blob" {
  name                   = basename(local_file.bastion_init_script.filename)
  storage_account_name   = azurerm_storage_account.scripts_storage.name
  storage_container_name = azurerm_storage_container.scripts_container.name
  type                   = "block"
  source                 = local_file.bastion_init_script.filename
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${local.prefix_kebap}-bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${local.prefix_kebap}-bastion"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "bastion_nic" {
  name                      = "${local.prefix_kebap}-${var.bastion_name}-nic"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id

  ip_configuration {
    name                          = "${local.prefix_kebap}-${var.bastion_name}-ipconfig"
    subnet_id                     = azurerm_subnet.on_premise_vm_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${local.prefix_kebap}-${var.bastion_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_machine" "bastion_vm" {
  name                  = "${local.prefix_kebap}-${var.bastion_name}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.bastion_nic.id]
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
    name              = "${local.prefix_kebap}-${var.bastion_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "256"
  }

  os_profile {
    computer_name  = var.bastion_name
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

resource "azurerm_virtual_machine_extension" "bastion_vm_ext" {
  name                 = "${local.prefix_kebap}-${var.bastion_name}-vm-ext"
  virtual_machine_id   = azurerm_virtual_machine.bastion_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["${azurerm_storage_account.scripts_storage.primary_blob_endpoint}${azurerm_storage_container.scripts_container.name}/${azurerm_storage_blob.vm_init_script_blob.name}"],
        "commandToExecute": "/bin/bash ./${azurerm_storage_blob.vm_init_script_blob.name}"
    }
SETTINGS

  depends_on = [local_file.bastion_init_script]
}
