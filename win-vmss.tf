resource "azurerm_windows_virtual_machine_scale_set" "win-vmss" {
  name                 = "win-vmss"
  computer_name_prefix = "zb"
  resource_group_name  = azurerm_resource_group.zero-rg.name
  location             = azurerm_resource_group.zero-rg.location
  sku                  = "Standard_F2"
  instances            = 2
  upgrade_mode         = "Automatic"
  admin_username       = "adminuser"
  admin_password       = data.azurerm_key_vault_secret.kv_secret_web.value

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.web-subnet.id
      # application_gateway_backend_address_pool_ids = [azurerm_application_gateway.zero-appgw.backend_address_pool[0].id] 
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.zero-appgw.backend_address_pool[*].id
    }
  }

  depends_on = [
    azurerm_virtual_network.zero-vnet
  ]
}

# resource "azurerm_network_interface" "vmss-nic" {
#   name                = "web-nic"
#   location            = azurerm_resource_group.zero-rg.location
#   resource_group_name = azurerm_resource_group.zero-rg.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.web-subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }

#   depends_on = [
#     azurerm_virtual_network.zero-vnet,
#     azurerm_subnet.web-subnet
#   ]
# }

resource "azurerm_virtual_machine_scale_set_extension" "win-vmss_extension" {
  name                         = "webvmss-extension"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.win-vmss.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"
  depends_on = [
    azurerm_storage_blob.IIS_config_image
  ]

  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.zero-sa.name}.blob.core.windows.net/data/IIS_Config_images.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config_images.ps1"
    }
SETTINGS
}