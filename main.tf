resource "azurerm_resource_group" "zero-rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "zero-vnet" {
  name                = "zero-vnet"
  location            = azurerm_resource_group.zero-rg.location
  resource_group_name = azurerm_resource_group.zero-rg.name
  address_space       = ["10.0.0.0/16"]
  depends_on = [
    azurerm_resource_group.zero-rg
  ]
}

resource "azurerm_public_ip" "zero-agw_pip" {
  name                = "agw-pip"
  resource_group_name = azurerm_resource_group.zero-rg.name
  location            = azurerm_resource_group.zero-rg.location
  allocation_method   = "Dynamic"
  # allocation_method   = "Static" //appgateway with SKU WAF can only reference public ip with Basic SKU.
  # sku                 = "Standard" //appgateway with SKU WAF can only reference public ip with Basic SKU.
}

resource "azurerm_application_gateway" "zero-appgw" {
  name                = "appgateway"
  resource_group_name = azurerm_resource_group.zero-rg.name
  location            = azurerm_resource_group.zero-rg.location

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "zero-gateway-ip-configuration"
    subnet_id = azurerm_subnet.agw-subnet.id
  }

  frontend_port {
    name = "frontend_port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend_ip_configuration"
    public_ip_address_id = azurerm_public_ip.zero-agw_pip.id
  }

  backend_address_pool {
    name = "imagepool"
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    # path                  = ""
    port            = 80
    protocol        = "Http"
    request_timeout = 60
    # probe_name      = "be-probe" ////probe does not support Priority for the selected SKU tier WAF.
  }

  # probe {
  #   name                = "be-probe"
  #   host                = "127.0.0.1"
  #   interval            = 30
  #   timeout             = 30
  #   unhealthy_threshold = 3
  #   protocol            = "Http"
  #   port                = 80
  #   path                = "/images/default.html"
  # }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend_ip_configuration"
    frontend_port_name             = "frontend_port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "RoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "imagepool"
    backend_http_settings_name = "http-setting"
    # priority                   = 10   //RoutingRule does not support Priority for the selected SKU tier WAF.
  }
}