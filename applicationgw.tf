locals {
  backend_address_pool_name      = "${azurerm_virtual_network.zero-vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.zero-vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.zero-vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.zero-vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.zero-vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.zero-vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.zero-vnet.name}-rdrcfg"
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
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.zero-agw_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
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
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    # priority                   = 10   //RoutingRule does not support Priority for the selected SKU tier WAF.
  }
}