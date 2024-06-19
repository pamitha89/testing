data "azurerm_virtual_network" "vnt" {
  name                 = "synapse-test"
  resource_group_name  = "vnets"
}

# Query - existing subnet
data "azurerm_subnet" "pepstasbnt" {
  
  name                 = "default"
  resource_group_name  = "vnets"
  virtual_network_name = data.azurerm_virtual_network.vnt.name
    
  depends_on = [data.azurerm_virtual_network.vnt]
}


data "azurerm_resource_group" "arg" {
  name = var.resource_group_name
}

data "azurerm_private_dns_zone" "dnszone" {
  #provider = azurerm.CoreServices

  for_each            = var.azurePrivateDNS
  name                = each.value
  resource_group_name = "vnets"
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {
}
data "azurerm_private_dns_zone" "syn_st_zone_blob" {
  #provider = azurerm.CoreServices
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "vnets"
}

data "azurerm_private_dns_zone" "syn_st_zone_dfs" {
  #provider = azurerm.CoreServices
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = "vnets"
}

# Linking of DNS zones to Virtual Network



# Private Endpoint configuration

resource "azurerm_private_endpoint" "syn_st_pe_blob" {
  name                = "pe-${azurerm_storage_account.str.name}-blob"
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.pepstasbnt.id

  private_service_connection {
    name                           = "psc-blob-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.str.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.syn_st_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "syn_st_pe_dfs" {
  name                = "pe-${azurerm_storage_account.str.name}-dfs"
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.pepstasbnt.id

  private_service_connection {
    name                           = "psc-dfs-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.str.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.syn_st_zone_dfs.id]
  }
}
