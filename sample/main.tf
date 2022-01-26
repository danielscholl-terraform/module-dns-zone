provider "azurerm" {
  features {}
}

variable "dns_zone" {
  type = string
}

variable "dns_zone_group" {
  type = string
}

variable "dns_zone_subscription" {
  type = string
}

data "azurerm_subscription" "current" {
}

module "resource_group" {
  source = "git::https://github.com/danielscholl-terraform/module-resource-group?ref=v1.0.0"

  name     = "iac-terraform"
  location = "eastus2"

  resource_tags = {
    iac = "terraform"
  }
}

resource "azurerm_public_ip" "main" {
  name                = format("%s-ip", module.resource_group.name)
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"

  sku = "Standard"

  tags = {
    iac = "terraform"
  }
}


#-------------------------------
# Azure DNS Record
#-------------------------------
module "dns" {
  source = "../"

  child_domain_resource_group_name = module.resource_group.name
  child_domain_subscription_id     = data.azurerm_subscription.current.subscription_id
  child_domain_prefix              = "terraform"

  parent_domain_subscription_id     = var.dns_zone_subscription
  parent_domain_resource_group_name = var.dns_zone_group
  parent_domain                     = var.dns_zone

  tags = {
    iac = "terraform"
  }
}

resource "azurerm_dns_a_record" "appcluster" {
  name                = "iac"
  zone_name           = module.dns.name
  resource_group_name = module.resource_group.name
  ttl                 = 60
  records             = [azurerm_public_ip.main.ip_address]
}
