resource "databricks_metastore_assignment" "workspace_assignment" {
  provider     = databricks.accounts
  metastore_id = data.databricks_current_metastore.metastore_id
  workspace_id = data.azurerm_databricks_workspace.dbx_workspaces.workspace_id
}

resource "databricks_credential" "storage_credential" {
  name = "stc_${var.project}_${var.environment}_001"
  azure_managed_identity {
    access_connector_id = data.azurerm_key_vault_secret.secret_access_connector_id.value
  }
  isolation_mode = "ISOLATION_MODE_ISOLATED"
  purpose        = "STORAGE"
  force_update   = true
  owner          = data.databricks_current_metastore.metastore.metastore_info[0].owner
}

resource "databricks_external_location" "external_location_metastore" {
  name            = "el_metastore_${var.environment}_001"
  url             = "abfss://metastore@${local.adls["metastore"]}.dfs.core.windows.net/"
  credential_name = databricks_credential.storage_credential.name
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  force_update    = true
  owner           = data.databricks_current_metastore.metastore.metastore_info[0].owner
}

resource "databricks_external_location" "external_location_shared" {
  name            = "el_shared_${var.environment}_001"
  url             = "abfss://shared@${local.adls["shared"]}.dfs.core.windows.net/"
  credential_name = databricks_credential.storage_credential.name
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  force_update    = true
  owner           = data.databricks_current_metastore.metastore.metastore_info[0].owner
}

resource "databricks_catalog" "catalog" {
  name           = "cat_${var.environment}"
  storage_root   = databricks_external_location.external_location_metastore.url
  isolation_mode = "ISOLATED"
  owner          = data.databricks_current_metastore.metastore.metastore_info[0].owner
}

resource "databricks_schema" "schema" {
  for_each     = { for s in local.schemas : s.name => s }
  catalog_name = databricks_catalog.catalog.name
  name         = each.value.name
  owner        = data.databricks_current_metastore.metastore.metastore_info[0].owner
}