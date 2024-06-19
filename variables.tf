variable "resource_group_name" {
  description = "(Required) The name of an existing resource group to be imported."
  type        = string
  default = "arg-dev-r1-Marktest-01"
}

variable "storage_tier" {
  type        = string
  description = "(Optional) Defines the Tier to use for this storage account."
  default     = "Standard"
}

variable "storage_replication" {
  type        = string
  description = " (Optional) Defines the type of replication to use for this storage account."
  default     = "LRS"
}

variable "storage_kind" {
  type        = string
  description = "(Optional) Defines the access tier for this storage acccount."
  default     = "StorageV2"
}

variable "stroage_access_tier" {
  type        = string
  description = "(Optional) Defines the access tier for the Stroage Account."
  default     = "Hot"
}
variable "enable_hns" {
  type        = bool
  description = "(Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2."
  default     = true
}



variable "name" {
  type        = string
  description = "(Required) Specifies the name which should be used for this synapse Workspace."
  default = "syntest01"
  }
/*ariable "identity_type" {
  type        = string
  description = "(Optional) Specifies the type of Managed Service Identity that should be configured on this Synapse Workspace."
  default     = "UserAssigned"
}
variable "identity_ids" {
  type        = list(string)
  description = "(Optional) A list of User Assigned Identity IDs to be assigned to this Synapse Workspace."
  default     = null
}*/


variable "purview_id" {
  type        = string
  description = "(Optional) The ID of purview account."
  default     = null
}
/*
variable "aad_admin" {
  type = object({
    login     = string
    object_id = string
    tenant_id = string
  })
  description = "(Optional) The 'login', 'object id' and 'tenant id' of the Azure AD Administrator of this Synapse Workspace."
  default = {
    login     = "corp-gs-epicon-admins"
    object_id = data.azurerm_client_config.current.object_id #var.object_id
    tenant_id = data.azurerm_client_config.current.object_id #var.tenant_id 
    azuread_authentication_only = true    
  }
  
}

variable "public_network_access_enabled" {
  type        = bool
  description = "(Optional) Whether public network access is allowed for the Synapse Workspace."
  default     = false
}*/

variable "enable_managed_vnet" {
  type        = bool
  description = "(Optional) Is Virtual Network enabled for all computes in this workspace?"
  default     = true
}
/*
variable "dep_enabled" {
  type        = bool
  description = "(Optional) Is data exfiltration protection enabled in this workspace?"
  default     = true
}*/

variable "data_exfiltration_protection_enabled" {
  type = bool
  default = true
}



variable "enable_azuread_administrator" {
  description = "Flag to enable Azure AD administrator"
  type        = bool
  default     = true
}


variable "resource_to_connect" {
  type = list(string)
  default = ["dfs","blob"]
}
variable "azurePrivateDNS" {
  type        = map(any)
  description = "Azure Private DNS mapping"
  default = {
    "sites"     = "privatelink.azurewebsites.net"
    "blob"      = "privatelink.blob.core.windows.net"
    "sqlServer" = "privatelink.database.windows.net"
    "file"      = "privatelink.file.core.windows.net"
    "queue"     = "privatelink.queue.core.windows.net"
    "table"     = "privatelink.table.core.windows.net"
    "vault"     = "privatelink.vaultcore.azure.net"
    "web"       = "privatelink.web.core.windows.net"
    "dfs"       = "privatelink.dfs.core.windows.net"
    "dev"   = "privatelink.dev.azuresynapse.net"
  }
}

