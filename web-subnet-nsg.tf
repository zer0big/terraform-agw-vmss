resource "azurerm_subnet" "web-subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.zero-rg.name
  virtual_network_name = azurerm_virtual_network.zero-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.zero-vnet
  ]
}

resource "azurerm_subnet" "agw-subnet" {
  name                 = "agw-subnet"
  resource_group_name  = azurerm_resource_group.zero-rg.name
  virtual_network_name = azurerm_virtual_network.zero-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [
    azurerm_virtual_network.zero-vnet
  ]
}

resource "azurerm_network_security_group" "zero-nsg" {
  name                = "webvm-nsg"
  location            = azurerm_resource_group.zero-rg.location
  resource_group_name = azurerm_resource_group.zero-rg.name
}

locals {
  app_inbound_ports_map = {
    "100" : "80", # If the key starts with a number, you must use the colon syntax ":" instead of "="
    # "110" : "3389"
  }
}

resource "azurerm_network_security_rule" "zero-nsg_rule" {
  for_each                    = local.app_inbound_ports_map
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.zero-rg.name
  network_security_group_name = azurerm_network_security_group.zero-nsg.name
  depends_on = [
    azurerm_network_security_group.zero-nsg
  ]
}

resource "azurerm_subnet_network_security_group_association" "zero-nsg_association" {
  subnet_id                 = azurerm_subnet.web-subnet.id
  network_security_group_id = azurerm_network_security_group.zero-nsg.id
}

# # azurerm_virtual_network_gateway_connection
# resource "azurerm_subnet" "gw-subnet" {
#   name                 = "GatewaySubnet"
#   resource_group_name  = azurerm_resource_group.zero-rg.name
#   virtual_network_name = azurerm_virtual_network.zero-vnet.name
#   address_prefixes     = ["10.0.3.0/28"]
# }

# resource "azurerm_local_network_gateway" "onpremise" {
#   name                = "onpremise"
#   location            = azurerm_resource_group.zero-rg.location
#   resource_group_name = azurerm_resource_group.zero-rg.name
#   gateway_address     = "168.62.225.23"
#   address_space       = ["10.1.1.0/24"]
# }

# resource "azurerm_public_ip" "vpn-pip" {
#   name                = "pip"
#   location            = azurerm_resource_group.zero-rg.location
#   resource_group_name = azurerm_resource_group.zero-rg.name
#   allocation_method   = "Dynamic"
# }

# resource "azurerm_virtual_network_gateway" "zero-vpn" {
#   name                = "vnetgw"
#   location            = azurerm_resource_group.zero-rg.location
#   resource_group_name = azurerm_resource_group.zero-rg.name

#   type     = "Vpn"
#   vpn_type = "RouteBased"

#   active_active = false
#   enable_bgp    = false
#   sku           = "Basic"

#   ip_configuration {
#     public_ip_address_id          = azurerm_public_ip.vpn-pip.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.gw-subnet.id
#   }
# }

# resource "azurerm_virtual_network_gateway_connection" "onpremise" {
#   name                = "onpremise"
#   location            = azurerm_resource_group.zero-rg.location
#   resource_group_name = azurerm_resource_group.zero-rg.name

#   type                       = "IPsec"
#   virtual_network_gateway_id = azurerm_virtual_network_gateway.zero-vpn.id
#   local_network_gateway_id   = azurerm_local_network_gateway.onpremise.id

#   shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
# }