provider "azurerm" {
  # Configuration options
  features {}
  subscription_id = var.subscription_id
}

provider "databricks" {
  alias           = "accounts"
  host            = "https://accounts.azuredatabricks.net"
  account_id      = var.dbx_account_id
  azure_tenant_id = data.azurerm_client_config.current.tenant_id
}

provider "databricks" {
  alias = "workspace"
  host  = data.azurerm_databricks_workspace.dbx_workspace.workspace_url
}
