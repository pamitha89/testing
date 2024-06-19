locals {
  resource_group_name = data.azurerm_resource_group.arg.name
  location            = data.azurerm_resource_group.arg.location 
  basename = "ajtest"
}

resource "azurerm_storage_account" "str" {
  
  name                     = "stadevr1markt910"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = var.storage_kind
  access_tier              = var.stroage_access_tier
  is_hns_enabled           = var.enable_hns
   public_network_access_enabled     = false
   allow_nested_items_to_be_public   = false

  network_rules {
    default_action = false ? "Deny" : "Allow" # each.value.denyPublicAccess == true ? "Deny" : "Allow"
  }
  /*network_rules  {
    bypass         = ["AzureServices"]   # option "None"cd en  
    default_action = "Deny"             # option "Deny" or "Allow"
    ip_rules       = ["220.233.4.0/23"]#options "["10.10.0.0/26", "1.2.3.4/32"]" or [] example "220.233.4.12/30"
    #virtual_network_subnet_ids = [data.azurerm_subnet.pepstasbnt.id]
  }*/
}
#Provision a Data Lake Gen2 File System within an Azure Storage Account
resource "azurerm_storage_data_lake_gen2_filesystem" "dlg2" {
  name               = "fsstadevr1marktes0"
  #storage_account_id = var.storage_account_id
  storage_account_id = azurerm_storage_account.str.id
  depends_on         = [
    time_sleep.role_assignment_sleep,
    azurerm_role_assignment.role_assignment
    ]
}


resource "azurerm_synapse_workspace" "syn" {
  name                                 = "sawstadevr1markt910"
  resource_group_name                  = local.resource_group_name
  location                             = local.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.dlg2.id
  sql_administrator_login              = "sslqadmin"
  sql_administrator_login_password     = "3AT@pples!!!"
  public_network_access_enabled        = false
  managed_virtual_network_enabled      = var.enable_managed_vnet
  data_exfiltration_protection_enabled = var.data_exfiltration_protection_enabled #var.enable_managed_vnet # && var.dep_enabled ? var.dep_enabled : false
  managed_resource_group_name          = "managedrg"
  azuread_authentication_only          = true 
  #azureADOnlyAuthentication             = true
  
  # purview_id = var.purview_id
  #aad_admin  = [var.aad_admin]
  # aad_admin  {
  #   login     = "testuser@ajitpatelhotmail.onmicrosoft.com"
  #   object_id = data.azurerm_client_config.current.object_id #var.object_id
  #   tenant_id = data.azurerm_client_config.current.object_id #var.tenant_id 
    
  # }
  /*
    dynamic "identity" {
    for_each = var.identity_type != null ? ["identity"] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }
  */
 identity {
    type = "SystemAssigned"
  }

}

/*
resource "azurerm_synapse_workspace_aad_admin" "example" {
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  login                =  "AzureAD Admin"
  object_id            = data.azurerm_client_config.current.object_id
  tenant_id            = data.azurerm_client_config.current.tenant_id 
}*/

resource "azurerm_synapse_spark_pool" "sparkpool" {
  name                 = "example"
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Large"
  cache_size           = 100
  spark_version        = "3.4"

  auto_scale {
    max_node_count = 45
    min_node_count = 3
  }
}
/*
resource "azurerm_synapse_firewall_rule" "example" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}*/
resource "azurerm_synapse_managed_private_endpoint" "example" {
  name                 = "example-endpoint"
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  target_resource_id   = azurerm_storage_account.str.id
  subresource_name     = "blob"  
  depends_on = [ azurerm_private_endpoint.syn_ws_pe_dev,
  azurerm_private_endpoint.syn_ws_pe_sql,
  azurerm_private_endpoint.syn_ws_pe_sqlondemand ]
  
}

# resource "azurerm_private_endpoint" "main" {  
#   for_each = { for i, v in var.resource_to_connect : i => v }

#   name                 = "pep-${var.name}"
#   location             = local.location
#   resource_group_name  = var.resource_group_name
#   subnet_id            = data.azurerm_subnet.pepstasbnt.id
#   private_service_connection {
#     name                           = "pep-${var.name}-psc"
#     private_connection_resource_id = azurerm_synapse_workspace.syn.id    
#     subresource_names              = [each.value]
#     is_manual_connection           = false
#   }  

# }

# resource "azurerm_private_dns_a_record" "dnsamain" {
#   depends_on = [
#     data.azurerm_resource_group.arg,
#     azurerm_private_endpoint.main
#   ]
#   provider = azurerm.CoreServices

#   for_each = { for i, v in var.resource_to_connect : i => v }

#   name                = "${var.name}"
#   zone_name           = data.azurerm_private_dns_zone.dnszone[each.value].name
#   resource_group_name = data.azurerm_private_dns_zone.dnszone[each.value].resource_group_name
#   ttl                 = 10
#   records             = azurerm_private_endpoint.main[each.key].custom_dns_configs[0].ip_addresses
  
  
# }


resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_storage_account.str.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "time_sleep" "role_assignment_sleep" {
  create_duration = "90s"

  triggers = {
    role_assignment = azurerm_role_assignment.role_assignment.id
  }
}

resource "azurerm_role_assignment" "syn_st_role_si_sbdc" {
  scope                = azurerm_storage_account.str.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn.identity[0].principal_id
}

resource "azurerm_role_assignment" "syn_st_role_si_c" {
  scope                = azurerm_storage_account.str.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.syn.identity[0].principal_id
}

resource "azurerm_private_endpoint" "syn_ws_pe_dev" {
  name                = "pe-${azurerm_synapse_workspace.syn.name}-dev"
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.pepstasbnt.id
  ip_configuration {
    name = "devip"
    private_ip_address = "10.0.0.211"
     member_name = "Dev"
     subresource_name = "Dev"

  }
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [ "/subscriptions/2305a573-07dc-4b80-b2f8-e218b4f72f77/resourceGroups/arg-dev-r1-marktest-01/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net" ]
  }

  private_service_connection {
    name                           = "psc-dev-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.syn.id
    subresource_names              = ["Dev"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "syn_ws_pe_sql" {
  name                = "pe-${azurerm_synapse_workspace.syn.name}-sql"
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.pepstasbnt.id
   ip_configuration {
    name = "devip"
    private_ip_address = "10.0.0.212"
     member_name = "Sql"
     subresource_name = "Sql"

  }
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [ "/subscriptions/2305a573-07dc-4b80-b2f8-e218b4f72f77/resourceGroups/arg-dev-r1-marktest-01/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net" ]
  }
  private_service_connection {
    name                           = "psc-sql-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.syn.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "syn_ws_pe_sqlondemand" {
  name                = "pe-${azurerm_synapse_workspace.syn.name}-sqlondemand"
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.pepstasbnt.id
   ip_configuration {
    name = "devip"
    private_ip_address = "10.0.0.213"
     member_name = "SqlOnDemand"
     subresource_name = "SqlOnDemand"

  }
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [ "/subscriptions/2305a573-07dc-4b80-b2f8-e218b4f72f77/resourceGroups/arg-dev-r1-marktest-01/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net" ]
  }
  private_service_connection {
    name                           = "psc-sqlondemand-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.syn.id
    subresource_names              = ["SqlOnDemand"]
    is_manual_connection           = false
  }
}
/*
resource "azurerm_private_endpoint" "str" {
  
  name                 = "pep-ajittest01"
  location             = local.location
  resource_group_name  = var.resource_group_name
  subnet_id            = data.azurerm_subnet.pepstasbnt.id

  private_service_connection {
    name                           = "psc-ajittest01"
    private_connection_resource_id = azurerm_storage_account.str.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  
}

resource "azurerm_private_dns_a_record" "dns" {
  depends_on = [
    azurerm_private_endpoint.main
  ]
  provider = azurerm.CoreServices
  
  name                = "ajittest01-arecord"
  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = "arg-cre-r1-privatedns-01"
  ttl                 = 10
  records             = azurerm_private_endpoint.str.custom_dns_configs[0].ip_addresses

  
}
*/



















/*
resource "azurerm_role_assignment" "syn_st_role_admin_sbdc" {
  scope                = var.storage_account_id #azurerm_storage_account.syn_st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "syn_st_role_si_sbdc" {
  scope                = var.storage_account_id
  role_definition_name = "Svar.storage_account_idtorage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn.identity[0].principal_id
}

resource "azurerm_role_assignment" "syn_st_role_si_c" {
  scope                = var.storage_account_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.syn.identity[0].principal_id
}

variable "existing_storage_account" {
  description = "The storage account to deploy to"
  default = "stadevr1marktest90"
}

variable "create_container_name" {
  description = "The name of the storage resource to create"
   default = "fsstadevr1marktest90"
}

module "lake-storage-analytics" {
  source = "./module"
  #existing_resource_group = var.resource_group_name
  existing_storage_account = "stadevr1marktest90"
  create_container_name = "fsstadevr1marktest90"
}*/
