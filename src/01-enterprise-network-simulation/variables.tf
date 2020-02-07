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

/* ---- Bastion ---- */
variable "proxy_name" {
  type    = string
  default = "proxy"
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
      address_space  = ["10.10.0.0/22"],
      gateway_subnet = "10.10.0.0/24",
      nva_subnet     = "10.10.1.0/24"
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
    /*
    s2 = {
      vnet_cidr = ["10.50.1.0/24"]
      subnet    = "10.50.1.0/24"
    },
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
