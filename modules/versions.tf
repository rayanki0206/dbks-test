terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">=1.28.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.83.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
