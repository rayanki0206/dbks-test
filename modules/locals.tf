
locals {
  derive_functional_area = {
    "commercial"      = "COM"
    "dataops"         = "DAT"
    "global services" = "GLO"
    "it"              = "IT"
    "m&q"             = "MNQ"
    "r&d"             = "RND"
  }
  storage_account_functional_area = {
    "commercial"      = "comm"
    "dataops"         = "edna"
    "global services" = "glbl"
    "it"              = "it"
    "m&q"             = "mq"
    "r&d"             = "rd"
  }
  data_lake_functionl_area = {
    "commercial"      = "comm"
    "dataops"         = "edna"
    "global services" = "global"
    "it"              = "it"
    "m&q"             = "mq"
    "r&d"             = "rd"
  }
  dl_functional_area       = lookup(local.data_lake_functionl_area, lower(var.functional_area), "default_value")
  st_functional_area       = lookup(local.storage_account_functional_area, lower(var.functional_area), "default_value")
  ad_group_functional_area = lookup(local.derive_functional_area, lower(var.functional_area), "default_value")
  #functional_area3 = lower(lookup(local.derive_functional_area, lower(var.functional_area), "default_value"))
  spn_functional_area = lower(lookup(local.derive_functional_area, lower(var.functional_area), "default_value"))

  # Derived variables

  region = {
    eastus      = "E1"
    westus      = "W1"
    westeurope  = "WE"
    northeurope = "NE"
    amsterdam   = "AM"
    ashburn     = "AB"
  }
  app                    = upper(var.appmnemonic)
  env1                   = upper(var.environment) == "PROD" ? "PROD" : "NONPROD"
  env2                   = upper(substr(var.environment, 0, 1))
  env3                   = upper(var.environment) == "PROD" ? "prod" : "nonprod"
  ad_admins_group        = "AD-SEC-ALL-${local.ad_group_functional_area}-${local.app}-ADMINS"
  ad_developers_group    = "AD-SEC-ALL-${local.ad_group_functional_area}-${local.app}-DEVELOPERS"
  az_ad_admins_group     = "AZ-SEC-${local.env1}-${local.ad_group_functional_area}-${local.app}-ADMINS"
  az_ad_developers_group = "AZ-SEC-${local.env1}-${local.ad_group_functional_area}-${local.app}-DEVELOPERS"
  # rg_name                = "B${local.env2}AZE1I${local.app}RG01"
  rg_name              = "B${local.env2}AZE1I${local.app}RG01"
  kv_name              = "B${local.env2}AZE1I${local.app}KV01"
  df_name              = "B${local.env2}AZE1I${local.app}DF01"
  la_name              = "B${local.env2}AZE1I${local.app}LA01"
  service_principal    = lower("app-${local.spn_functional_area}-${local.app}-${local.env3}")
  service_account_name = upper("SVC-${local.app}-${replace(var.data_product_name, " ", "")}-${upper(var.environment)}")
  ########################################################################
  dl_rg_name         = upper("b${lower(local.env2)}aze1i${local.st_functional_area}rg01}}")
  dl_storage_account = lower("b${lower(local.env2)}aze1i${local.st_functional_area}dl01}")
  dl_container       = replace(lower("${local.dl_functional_area}-${var.data_product_name}"), " ", "")
  synapse_server     = upper(var.environment) == "DEV" ? "b${lower(local.env2)}aze1isqdwdb01.database.windows.net" : "b${lower(local.env2)}aze1iednadb01.database.windows.net"
  synapse_db         = upper(var.environment) == "DEV" ? "B${local.env2}AZE1ISQDWSV01" : "B${local.env2}AZE1IEDNADW01"
  #dw_synapse_db        = var.env == "DEV" ? "b${lower(local.env2)}aze1isqdwdb01.database.windows.net\${local.synapse_db}" : "b${lower(local.env2)}aze1iednadb01.database.windows.net\${local.synapse_db}"
  databricksFolderName             = "${upper(local.dl_functional_area)} - ${replace(var.data_product_name, " ", "")} (${local.app})"
  databricks_wspace                = upper(var.environment) == "DEV" ? "B${local.env2}AZE1IDBRKSV01" : "B${local.env2}AZE1IEDNABK01"
  dbricks_ws_resourece_group       = upper(var.environment) == "DEV" ? "B${local.env2}AZE1IDBRKSV01" : "B${local.env2}AZE1IEDNARG01"
  dbricks_key_vault                = "B${local.env2}AZE1I${local.app}KV01"
  dbricks_key_vault_resource_group = "B${local.env2}AZE1I${local.app}RG01"
#   dbks_workspace = data.azurerm_resources.databricks.resources
#     valid_dbks = {for resource in data.azurerm_resources.databricks.resources : resource.name => resource
#     if contains(tolist([var.databricks_workspace_name]), resource.name)
#     }
# dbks_rg = local.valid_dbks
# dbks_rg_name = values(local.dbks_rg)[0].resource_group_name
dbks_workspace = data.azurerm_resources.databricks.resources

  valid_dbks = var.databricks_workspace_name != "" ? {
    for resource in local.dbks_workspace : resource.name => resource
    if contains(tolist([var.databricks_workspace_name]), resource.name)
  } : {}

  dbks_rg = var.databricks_workspace_name != "" ? local.valid_dbks : {}

  dbks_rg_name = var.databricks_workspace_name != "" && length(local.dbks_rg) > 0 ? values(local.dbks_rg)[0].resource_group_name : null

#   datafactory = data.azurerm_resources.df.resources
#   valid_df = {
#     for res in local.datafactory : res.name => res
#     if contains(tolist([var.datafactory]), res.name)
#   }
#   df         = local.valid_df
#   df_rg_name = values(local.df)[0].resource_group_name
  datafactory = data.azurerm_resources.df.resources

  valid_df = var.datafactory != "" ? {
    for res in local.datafactory : res.name => res
    if contains(tolist([var.datafactory]), res.name)
  } : {}

  df = var.datafactory != "" ? local.valid_df : {}

  df_rg_name = var.datafactory != "" && length(local.df) > 0 ? values(local.df)[0].resource_group_name : null

  key_vault = data.azurerm_resources.kv.resources

  valid_kv = var.keyvault != "" ? {
    for res in local.key_vault : res.name => res
    if contains(tolist([var.keyvault]), res.name)
  } : {}

  kv = var.keyvault != "" ? local.valid_kv : {}

  kv_rg_name = var.keyvault != "" && length(local.kv) > 0 ? values(local.kv)[0].resource_group_name : null
#   key_vault = data.azurerm_resources.kv.resources
#   valid_kv = {
#     for res in local.key_vault : res.name => res
#     if contains(tolist([var.keyvault]), res.name)
#   }
#   kv         = local.valid_kv
#   kv_rg_name = values(local.kv)[0].resource_group_name

  schema_readers_group = "AZ-SEC-${local.env1}-${local.ad_group_functional_area}-${local.app}-${upper(local.dl_functional_area)}${replace(var.data_product_name, " ", "")}Readers"

  schema_reader_role = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}DataReader"
  reader_role_name   = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}DataReader"
  reader_member_name = local.schema_readers_group

  schema_writer_role = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}DataWriter"

  schema_developer_role = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Developer"
  developer_role_name   = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Developer"
  developer_member_name = local.az_ad_developers_group

  schema_owner_role   = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Owner"
  owner_role_name     = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Owner"
  owner_member_name   = local.az_ad_admins_group
  owner_member_name_2 = "${local.env3}${local.dl_functional_area}Admins"

  ddl_admin_role_name  = "db_ddladmin"
  ddl_admin_membername = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Owner"

  schema        = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}"
  authorization = "${local.dl_functional_area}${replace(var.data_product_name, " ", "")}Owner"
  # adminuser                 = lower(var.admin_member)
  # devuser                   = lower(var.dev_member)
  svc_account_email = lower("${local.service_account_name}@sridhars2024.onmicrosoft.com")
  #databricks_users          = ["${local.adminuser}", "${local.devuser}"]
  databricks_clsuter_groups = ["cluster - General 01", "cluster - General 02"]
  databrick-host-url        = "https://${data.azurerm_databricks_workspace.dbs-ws.workspace_url}"
}