data "azurerm_key_vault" "key_vault" {
  name                = "kv-${var.project}-${var.environment}-${var.location_abbrv}-001"
  resource_group_name = "rg-${var.project}-shared-${var.environment}-${var.location_abbrv}-001"
}

data "azurerm_key_vault_secret" "secret_workspace_id" {
  name         = "databricks-workspace-id"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

data "azurerm_databricks_workspace" "dbx_workspaces" {
  name                = provider::azurerm::parse_resource_id(data.azurerm_key_vault_secret.secret_workspace_id.value)["resource_name"]
  resource_group_name = provider::azurerm::parse_resource_id(data.azurerm_key_vault_secret.secret_workspace_id.value)["resource_group_name"]
}

data "databricks_current_metastore" "metastore" {
  provider = databricks.accounts
}

data "azurerm_key_vault_secret" "secret_access_connector_id" {
  name         = "databricks-access-connector-id"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

data "azurerm_key_vault_secret" "secret_adls_metastore_id" {
  name         = "adls-metastore-id"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

data "azurerm_key_vault_secret" "secret_adls_shared_id" {
  name         = "adls-shared-id"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}