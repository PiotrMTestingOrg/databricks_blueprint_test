resource "azurerm_virtual_network" "virtual_network" {
  name                = "vnet-${var.project}-${var.environment}-${var.location_abbrv}-001"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
  address_space       = [var.cidr]
}

resource "azurerm_network_security_group" "nsg_workspace" {
  name                = "nsg-${var.project}-${var.environment}-${var.location_abbrv}-001"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
}

resource "azurerm_subnet" "subnet_host" {
  name                            = "snet_host"
  resource_group_name             = azurerm_resource_group.rg_network.name
  virtual_network_name            = azurerm_virtual_network.virtual_network.name
  address_prefixes                = [cidrsubnet(var.cidr, 3, 0)]
  default_outbound_access_enabled = false

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "host_association" {
  subnet_id                 = azurerm_subnet.subnet_host.id
  network_security_group_id = azurerm_network_security_group.nsg_workspace.id
}

resource "azurerm_subnet" "subnet_container" {
  name                            = "snet_container"
  resource_group_name             = azurerm_resource_group.rg_network.name
  virtual_network_name            = azurerm_virtual_network.virtual_network.name
  address_prefixes                = [cidrsubnet(var.cidr, 3, 1)]
  default_outbound_access_enabled = false

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "container_association" {
  subnet_id                 = azurerm_subnet.subnet_container.id
  network_security_group_id = azurerm_network_security_group.nsg_workspace.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "pip-${var.project}-${var.environment}-${var.location_abbrv}-001"
  location            = azurerm_resource_group.rg_network.location
  resource_group_name = azurerm_resource_group.rg_network.name
  allocation_method   = "Dynamic"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "ng-${var.project}-${var.environment}-${var.location_abbrv}-001"
  location            = azurerm_resource_group.rg_network.location
  resource_group_name = azurerm_resource_group.rg_network.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "host_association" {
  subnet_id      = azurerm_subnet.subnet_host.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_subnet_nat_gateway_association" "container_association" {
  subnet_id      = azurerm_subnet.subnet_container.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}