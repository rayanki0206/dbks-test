module "dbks" {
  source                    = "./modules"
  ad_admins_group           = var.ad_admins_group
  ad_developers_group       = var.ad_developers_group
  appmnemonic               = var.appmnemonic
  data_product_name         = var.data_product_name
  databricks_account_id     = var.databricks_account_id
  databricks_workspace_name = var.databricks_workspace_name
  datafactory               = var.datafactory
  environment               = var.environment
  functional_area           = var.functional_area
  service_principal         = var.service_principal
  subscription_id           = var.subscription_id
  keyvault                  = var.keyvault
}