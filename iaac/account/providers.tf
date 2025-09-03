provider "databricks" {
  alias           = "accounts"
  host            = "https://accounts.azuredatabricks.net"
  account_id      = var.dbx_account_id
  azure_tenant_id = data.azurerm_client_config.current.tenant_id
}