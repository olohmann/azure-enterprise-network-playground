locals {
}

data "template_file" "inventory_export_template" {
  template = <<__CFG__
[proxies]
${azurerm_network_interface.proxy_nic.private_ip_address} ansible_connection=ssh ansible_user=${var.admin_username}
__CFG__
}

resource "local_file" "inventory_export_file" {
  content  = data.template_file.inventory_export_template.rendered
  filename = "${path.module}/${local.prefix_kebap}-inventory.cfg"
}
