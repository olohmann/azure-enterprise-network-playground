variable "prefix" {
  type        = string
  default     = "contoso"
  description = "A prefix used for all resources in this example"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "The Azure region in which all resources in this example should be provisioned."
}

/* ---- Bastion ---- */
variable "bastion_name" {
  type    = string
  default = "bastion"
}

/* ---- Proxy ---- */
variable "proxy_server_name" {
  type    = string
  default = "proxy"
}

/* ---- DNS ---- */
variable "azure_private_dns_domain" {
  type    = string
  default = "private.contoso.net"
}

variable "dns_vm_name" {
  type    = string
  default = "dns"
}

variable "dns_private_azure_dns_forwarder_vm_name" {
  type    = string
  default = "dns-azure-private-dns-forwarder"
}

variable "dns_on_prem_vm_name" {
  type    = string
  default = "dns-on-prem"
}

/* ---- Spoke Sample VM ---- */
variable "spoke_vm_name" {
  type    = string
  default = "spoke"
}

/* ---- Virtual Machine ---- */
variable "vm_name" {
  type    = string
  default = "onpremweb"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "public_ssh_key_admin" {
  type        = string
  default     = ""
  description = "Per default your home ~/.ssh/id_rsa.pub key is being used."
}

/* --------------- Hub+Spoke Config ------------- */
variable "hub_vnet_configuration" {
  type = map
  default = {
    config = {
      address_space                      = ["10.10.0.0/22"],
      gateway_subnet                     = "10.10.0.0/24",
      nva_subnet                         = "10.10.1.0/24",
      dns_subnet                         = "10.10.2.0/24",
      private_azure_dns_forwarder_subnet = "10.10.3.0/24"
    }
  }
}

variable "spoke_vnets_configuration" {
  type = map
  default = {
    s1 = {
      vnet_cidr = ["10.50.0.0/24"]
      subnet    = "10.50.0.0/24"
    },
    s2 = {
      vnet_cidr = ["10.50.1.0/24"]
      subnet    = "10.50.1.0/24"
    }
    /*
    s3 = {
      vnet_cidr = ["10.50.2.0/24"]
      subnet    = "10.50.2.0/24"
    },
    s4 = {
      vnet_cidr = ["10.50.3.0/24"]
      subnet    = "10.50.3.0/24"
    },
    s5 = {
      vnet_cidr = ["10.50.4.0/24"]
      subnet    = "10.50.4.0/24"
    }
    */
  }
}
