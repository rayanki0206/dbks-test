provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "functional_area"
  subscription_id = var.subscription_id != "" ? var.subscription_id : var.functional_area == "global services" ? "34f22bc6-135a-4e3f-a2d9-28f2ea2e0607" : var.functional_area == "commercial" ? "0a0bdfa4-f261-493d-b02e-a1c114b4298f" : var.functional_area == "dataops" ? "897caaa4-0ac7-43e3-97b4-b0b57029410d" : var.functional_area == "it" ? "055ac988-501b-4788-9d86-8f43bcbd7ccf" : var.functional_area == "m&q" ? "765b7ef6-0d12-4313-b67f-11e9e85ee0d6" : var.functional_area == "r&d" ? "a357d9b0-e1a1-4278-bf00-8a143f3d5e89" : "3de5bb92-ec90-4c7e-af9b-90c3ed1cae76"
  features {

  }
}

provider "random" {
  # Configuration options for the provider (if any)
}
provider "azuread" {
  tenant_id = "ae78d6b1-0301-44e7-9e07-063a71208317"
}


provider "databricks" {
  alias                       = "azure_account"
  host                        = data.azurerm_databricks_workspace.dbs-ws.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.dbs-ws.id
  #account_id = local.account_id
  # account_id = data.azurerm_databricks_workspace.dbs-ws.id
  auth_type = "azure-cli"
  # ARM_USE_MSI environment variable is recommended
  # azure_use_msi = true
}
provider "databricks" {
alias = "second"
  #host       = "https://accounts.azuredatabricks.net"
account_id = local.account_id
}
 

data "azurerm_resources" "databricks" {
  type = "microsoft.databricks/workspaces"
}
# deploys databricks operations as per Dataproduct Spreadsheet
data "azurerm_databricks_workspace" "dbs-ws" {
  name                = var.databricks_workspace_name
  resource_group_name = local.dbks_rg_name
}


data "databricks_group" "admins" {
  provider     = databricks.azure_account
  count        = var.ad_admins_group != "" ? 1 : 0
  display_name = var.ad_admins_group
}
data "databricks_group" "developers" {
  provider     = databricks.azure_account
  count        = var.ad_developers_group != "" ? 1 : 0
  display_name = var.ad_developers_group
}

data "databricks_group" "clustergroups1" {
  provider     = databricks.azure_account
  display_name = "cluster - General 01"
}
data "databricks_group" "clustergroups2" {
  provider     = databricks.azure_account
  display_name = "cluster - General 02"
}

# Add group members to above created group.
resource "databricks_group_member" "admins" {
  provider  = databricks.azure_account
  count     = var.ad_admins_group != "" ? 1 : 0
  group_id  = data.databricks_group.clustergroups1.id
  member_id = data.databricks_group.admins[count.index].id #dbs-functionalgroup.id
  #depends_on = [data.databricks_group.admins]
}
resource "databricks_group_member" "dev" {
  provider  = databricks.azure_account
  count     = var.ad_developers_group != "" ? 1 : 0
  group_id  = data.databricks_group.clustergroups1.id
  member_id = data.databricks_group.developers[count.index].id #dbs-functionalgroup.id
  #depends_on = [data.databricks_group.admins]
}
resource "databricks_group_member" "admins2" {
  provider  = databricks.azure_account
  count     = var.ad_admins_group != "" ? 1 : 0
  group_id  = data.databricks_group.clustergroups2.id
  member_id = data.databricks_group.admins[count.index].id #dbs-functionalgroup.id
  #depends_on = [data.databricks_group.admins]
}
resource "databricks_group_member" "dev2" {
  provider  = databricks.azure_account
  count     = var.ad_developers_group != "" ? 1 : 0
  group_id  = data.databricks_group.clustergroups2.id
  member_id = data.databricks_group.developers[count.index].id #dbs-functionalgroup.id
  #depends_on = [data.databricks_group.admins]
}



# Create Folder in databricks
resource "databricks_directory" "my_custom_directory" {
  provider = databricks.azure_account
  path     = "/${local.databricksFolderName}"

}

# Manage Folder permissions for the group.

resource "databricks_permissions" "folder_usage_admins" {
  provider       = databricks.azure_account
  count          = var.ad_admins_group != "" ? 1 : 0
  directory_path = databricks_directory.my_custom_directory.path
  
  access_control {
    group_name       = data.databricks_group.admins[count.index].display_name
    permission_level = "CAN_MANAGE"
  }
}

resource "databricks_permissions" "folder_usage_developers" {
  provider       = databricks.azure_account
  count          = var.ad_developers_group != "" ? 1 : 0
  directory_path = databricks_directory.my_custom_directory.path
  access_control {
    group_name       = data.databricks_group.developers[count.index].display_name
    permission_level = "CAN_MANAGE"
  }
}

resource "databricks_permissions" "folder_usage_service_principal" {
  provider       = databricks.azure_account
  count          = var.service_principal != "" ? 1 : 0
  directory_path = databricks_directory.my_custom_directory.path
  access_control {
    service_principal_name = databricks_service_principal.service_principal[count.index].application_id
    permission_level       = "CAN_RUN"
  }
}

resource "databricks_permissions" "folder_usage_service_principal_datafactory" {
  provider       = databricks.azure_account
  count          = var.datafactory != "" ? 1 : 0
  directory_path = databricks_directory.my_custom_directory.path
  access_control {
    service_principal_name = databricks_service_principal.data_factory[count.index].application_id
    permission_level       = "CAN_RUN"
  }
}

data "azurerm_resources" "kv" {
  provider = azurerm.functional_area 
  type     = "microsoft.keyvault/vaults"
}
data "azurerm_resources" "df" {
  provider = azurerm.functional_area 
  type     = "microsoft.datafactory/factories"
}


data "azurerm_data_factory" "spn" {
  provider            = azurerm.functional_area 
  count               = var.datafactory != "" ? 1 : 0
  name                = var.datafactory
  resource_group_name = local.df_rg_name
}

resource "databricks_service_principal" "data_factory" {
  provider             = databricks.azure_account
  count                = var.datafactory != "" ? 1 : 0
  display_name         = data.azurerm_data_factory.spn[count.index].name
  application_id       = data.azurerm_data_factory.spn[count.index].identity[0].principal_id
  allow_cluster_create = true
}

data "azuread_service_principal" "spn" {
  count        = var.service_principal != "" ? 1 : 0
  display_name = var.service_principal
}
resource "databricks_service_principal" "service_principal" {
  provider             = databricks.azure_account
  count                = var.service_principal != "" ? 1 : 0
  display_name         = var.service_principal
  application_id       = data.azuread_service_principal.spn[count.index].client_id
  allow_cluster_create = true
  workspace_access     = true

}
data "databricks_group" "dbks_admins_group" {
  provider = databricks.azure_account
  display_name = "admins"
}

resource "databricks_group_member" "service_principal" {
  provider  = databricks.azure_account
  count     = var.service_principal != "" ? 1 : 0
  group_id  = data.databricks_group.dbks_admins_group.id
  member_id = databricks_service_principal.service_principal[0].id
 }

locals {
  account_id = var.databricks_account_id
# acl_roles = ["roles/servicePrincipal.user", "roles/servicePrincipal.manager"]
# admin_temp = tostring("${data.databricks_group.admins[0]}".acl_principal_id)
}

# resource "databricks_access_control_rule_set" "automation_sp_rule_set_user_admins" {
#   provider = databricks.azure_account
#   count = var.service_principal != "" && (var.ad_admins_group != "" || var.ad_developers_group != "") ? 1 : 0
  
#   name     = "accounts/${local.account_id}/servicePrincipals/${databricks_service_principal.service_principal[0].application_id}/ruleSets/default"
#   dynamic "grant_rules" {
#     for_each = var.ad_admins_group != "" ? [1] : []
#     content {
#       principals = [data.databricks_group.admins[0].acl_principal_id]
#       role       = "roles/servicePrincipal.user"
#     }
#   }
#   dynamic  "grant_rules"  {
#     for_each = var.ad_admins_group != "" ? [1] : []
#     content {
#     principals = [data.databricks_group.admins[0].acl_principal_id]
#     role       = "roles/servicePrincipal.manager"
#   }
#   }
#  dynamic "grant_rules" {
#     for_each = var.ad_developers_group != "" ? [1] : []
#     content {
#       principals = [data.databricks_group.developers[0].acl_principal_id]
#       role       = "roles/servicePrincipal.user"
#     }
#   }
#   dynamic  "grant_rules"  {
#     for_each = var.ad_developers_group != "" ? [1] : []
#     content {
#     principals = [data.databricks_group.developers[0].acl_principal_id]
#     role       = "roles/servicePrincipal.manager"
#   }
#   }
# }




#gives object id and tenant id that are used in keyvault
data "azurerm_client_config" "dbstfadmin" {

}

## Add the Seceret to KeyValut
data "azurerm_key_vault" "keyvault" {
  provider            = azurerm.functional_area #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  count               = var.keyvault != "" ? 1 : 0
  name                = var.keyvault
  resource_group_name = local.kv_rg_name
  # depends_on          = [module.keyvault, azurerm_key_vault_access_policy.tfadmin]
}



#### Create Secret Scope
resource "databricks_secret_scope" "secretscope_kv" {
  provider = databricks.azure_account
  count    = var.keyvault != "" ? 1 : 0
  name     = "AKV-${local.app}"
  # initial_manage_principal = "users"

  keyvault_metadata {
    resource_id = data.azurerm_key_vault.keyvault[count.index].id
    dns_name    = data.azurerm_key_vault.keyvault[count.index].vault_uri
  }
  #depends_on = [data.azurerm_key_vault.pat_keyvault]
}

#Create databricks acl 
resource "databricks_secret_acl" "secret_acl_admins" {
  provider   = databricks.azure_account
  count      = var.ad_admins_group != "" ? 1 : 0
  principal  = data.databricks_group.admins[count.index].display_name
  permission = "MANAGE"
  scope      = databricks_secret_scope.secretscope_kv[count.index].name
  # depends_on = [ azurerm_key_vault_secret.svctoken_kv, databricks_secret_scope.secretscope_kv ]
  #depends_on = [databricks_secret_scope.secretscope_kv]
}
resource "databricks_secret_acl" "secret_acl_developers" {
  provider   = databricks.azure_account
  count      = var.ad_developers_group != "" ? 1 : 0
  principal  = data.databricks_group.developers[count.index].display_name
  permission = "READ"
  scope      = databricks_secret_scope.secretscope_kv[count.index].name
  # depends_on = [ azurerm_key_vault_secret.svctoken_kv, databricks_secret_scope.secretscope_kv ]
  #depends_on = [databricks_secret_scope.secretscope_kv]
}
resource "databricks_secret_acl" "secret_acl_datafactory" {
  provider   = databricks.azure_account
  count      = var.service_principal != "" ? 1 : 0
  principal  = data.azurerm_data_factory.spn[count.index].identity[0].principal_id
  permission = "READ"
  scope      = databricks_secret_scope.secretscope_kv[count.index].name
  # depends_on = [ azurerm_key_vault_secret.svctoken_kv, databricks_secret_scope.secretscope_kv ]
  #depends_on = [databricks_secret_scope.secretscope_kv]
}
resource "databricks_secret_acl" "secret_acl_service_principal" {
  provider   = databricks.azure_account
  count      = var.service_principal != "" ? 1 : 0
  principal  = databricks_service_principal.service_principal[count.index].application_id
  permission = "READ"
  scope      = databricks_secret_scope.secretscope_kv[count.index].name
  # depends_on = [ azurerm_key_vault_secret.svctoken_kv, databricks_secret_scope.secretscope_kv ]
  #depends_on = [databricks_secret_scope.secretscope_kv]
}


#create job cluster pool
resource "databricks_instance_pool" "job_cluster" {
  provider                              = databricks.azure_account
  instance_pool_name                    = "${local.app}-Pool-General-JobClusters"
  min_idle_instances                    = 0
  idle_instance_autotermination_minutes = 60
  node_type_id                          = "Standard_L8s_v3"
  azure_attributes {
    availability = "ON_DEMAND_AZURE"
  }
  preloaded_spark_versions = [
    "10.4.x-scala2.12"
  ]
}


resource "databricks_permissions" "pool_usage_admins" {
  provider         = databricks.azure_account
  count            = var.ad_admins_group != "" ? 1 : 0
  depends_on       = [databricks_instance_pool.job_cluster]
  instance_pool_id = databricks_instance_pool.job_cluster.id

  access_control {
    group_name       = data.databricks_group.admins[count.index].display_name
    permission_level = "CAN_MANAGE"
  }
}

resource "databricks_permissions" "pool_usage_developers" {
  provider         = databricks.azure_account
  count            = var.ad_developers_group != "" ? 1 : 0
  depends_on       = [databricks_instance_pool.job_cluster]
  instance_pool_id = databricks_instance_pool.job_cluster.id

  access_control {
    group_name       = data.databricks_group.developers[count.index].display_name
    permission_level = "CAN_MANAGE"
  }
}

resource "databricks_permissions" "pool_usage_datafactory" {
  provider         = databricks.azure_account
  count            = var.datafactory != "" ? 1 : 0
  depends_on       = [databricks_instance_pool.job_cluster]
  instance_pool_id = databricks_instance_pool.job_cluster.id

  access_control {
    service_principal_name = databricks_service_principal.data_factory[count.index].application_id
    permission_level       = "CAN_ATTACH_TO"
  }
}

resource "databricks_permissions" "pool_usage_service_principal" {
  provider         = databricks.azure_account
  count            = var.service_principal != "" ? 1 : 0
  depends_on       = [databricks_instance_pool.job_cluster]
  instance_pool_id = databricks_instance_pool.job_cluster.id

  access_control {
    service_principal_name = databricks_service_principal.service_principal[count.index].application_id
    permission_level       = "CAN_ATTACH_TO"
  }
}

