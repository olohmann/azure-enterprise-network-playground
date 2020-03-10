locals {
  /* **************************************** */
  ansible_inventory_hosts = <<__CFG__
[proxies]
${azurerm_network_interface.proxy_nic.private_ip_address} ansible_connection=ssh ansible_user=${var.admin_username}

[dns]
${azurerm_network_interface.dns_nic.private_ip_address} ansible_connection=ssh ansible_user=${var.admin_username}

[dns-azure-private-dns-forwarder]
${azurerm_network_interface.dns_private_azure_dns_forwarder_nic.private_ip_address} ansible_connection=ssh ansible_user=${var.admin_username}

[dns-on-prem]
${azurerm_network_interface.dns_on_prem_nic.private_ip_address} ansible_connection=ssh ansible_user=${var.admin_username}
__CFG__

  /* **************************************** */
  ansible_on_prem_dns_coredns_corefile = <<__cfg__
${var.on_prem_dns_domain} {
  reload
  errors
  log
  whoami
}
__cfg__

  /* **************************************** */
  ansible_dns_coredns_corefile = <<__cfg__
. {
  reload
  errors
  log
  forward . 168.63.129.16
}

${var.on_prem_dns_domain} {
  reload
  errors
  log
  forward . ${cidrhost(azurerm_subnet.on_premise_proxy_subnet.address_prefix, 5)} {
    except ${var.azure_private_dns_domain}
  }
}
__cfg__

  /* **************************************** */
  ansible_dns_azure_private_dns_coredns_corefile = <<__cfg__
%{for zone in azurerm_private_dns_zone.spoke_private_dns_zone~}
${zone.name} {
  reload
  errors
  log
  azure ${zone.resource_group_name}:${zone.name} {
     tenant ${data.azurerm_client_config.current.tenant_id}
     client ${var.azure_private_dns_reader_client_id}
     subscription ${data.azurerm_client_config.current.subscription_id}
     secret ${var.azure_private_dns_reader_client_secret}
     access private
  }
}
%{endfor~}
__cfg__
}

resource "local_file" "on_prem_coredns_corefile" {
  content  = local.ansible_on_prem_dns_coredns_corefile
  filename = "${path.module}/../02-middleware-deployments/roles/cloudalchemy.coredns/templates/onprem_dns_corefile"
}

resource "local_file" "dns_coredns_corefile" {
  content  = local.ansible_dns_coredns_corefile
  filename = "${path.module}/../02-middleware-deployments/roles/cloudalchemy.coredns/templates/dns_corefile"
}

resource "local_file" "inventory_export_file" {
  content  = local.ansible_inventory_hosts
  filename = "${path.module}/../02-middleware-deployments/inventory/hosts"
}

resource "local_file" "dns_azure_private_dns_coredns_corefile" {
  content  = local.ansible_dns_azure_private_dns_coredns_corefile
  filename = "${path.module}/../02-middleware-deployments/roles/cloudalchemy.coredns/templates/dns_azure_private_dns_corefile"
}
/* ---------------- */

output "inventory_hosts" {
  value = local.ansible_inventory_hosts
}

output "on_prem_coredns_corefile" {
  value = local.ansible_on_prem_dns_coredns_corefile
}

output "dns_coredns_corefile" {
  value = local.ansible_dns_coredns_corefile
}

output "dns_azure_private_dns_coredns_corefile" {
  value     = local.ansible_dns_azure_private_dns_coredns_corefile
  sensitive = true
}
