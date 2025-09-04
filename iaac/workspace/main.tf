resource "databricks_metastore_assignment" "workspace_assignment" {
  provider     = databricks.accounts
  metastore_id = data.databricks_current_metastore.metastore.id
  workspace_id = data.azurerm_databricks_workspace.dbx_workspace.workspace_id
}

# Assign Entra Groups to onboarded workspaces
resource "databricks_mws_permission_assignment" "developer_group_assignment" {
  provider     = databricks.accounts
  workspace_id = data.azurerm_databricks_workspace.dbx_workspace.workspace_id
  principal_id = data.databricks_group.developer_group.id
  permissions  = ["USER"]
  depends_on   = [databricks_metastore_assignment.workspace_assignment]
}

# Assign Entra Groups to onboarded workspaces
resource "databricks_mws_permission_assignment" "admin_group_assignment" {
  provider     = databricks.accounts
  workspace_id = data.azurerm_databricks_workspace.dbx_workspace.workspace_id
  principal_id = data.databricks_group.admin_group.id
  permissions  = ["ADMIN"]
  depends_on   = [databricks_metastore_assignment.workspace_assignment]
}

resource "databricks_credential" "storage_credential" {
  provider = databricks.workspace
  name     = "stc_${var.project}_${var.environment}_001"
  azure_managed_identity {
    access_connector_id = data.azurerm_key_vault_secret.secret_access_connector_id.value
  }
  isolation_mode = "ISOLATION_MODE_ISOLATED"
  purpose        = "STORAGE"
  force_update   = true
  owner          = data.databricks_group.admin_group.display_name
}

resource "databricks_external_location" "external_location_metastore" {
  provider        = databricks.workspace
  name            = "el_metastore_${var.environment}_001"
  url             = "abfss://metastore@${local.adls["metastore"]}.dfs.core.windows.net/"
  credential_name = databricks_credential.storage_credential.name
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  force_update    = true
  owner           = data.databricks_group.admin_group.display_name
}

resource "databricks_external_location" "external_location_shared" {
  provider        = databricks.workspace
  name            = "el_shared_${var.environment}_001"
  url             = "abfss://shared@${local.adls["shared"]}.dfs.core.windows.net/"
  credential_name = databricks_credential.storage_credential.name
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  force_update    = true
  owner           = data.databricks_group.admin_group.display_name
}

resource "databricks_catalog" "catalog" {
  provider       = databricks.workspace
  name           = "cat_${var.environment}"
  storage_root   = databricks_external_location.external_location_metastore.url
  isolation_mode = "ISOLATED"
  owner          = data.databricks_group.admin_group.display_name
}

resource "databricks_grant" "admin_catalog_grant" {
  provider = databricks.workspace
  catalog  = databricks_catalog.catalog.name

  principal  = data.databricks_group.admin_group.display_name
  privileges = ["ALL_PRIVILEGES", "MODIFY"]
}

resource "databricks_grant" "developer_catalog_grant" {
  provider = databricks.workspace
  catalog  = databricks_catalog.catalog.name

  principal  = data.databricks_group.admin_group.display_name
  privileges = ["USE_CATALOG", "USE_SCHEMA", "EXECUTE", "READ_VOLUME", "SELECT", "MODIFY", "WRITE_VOLUME", "CREATE_FUNCTION", "CREATE_TABLE", "CREATE_VIEW"]
}

resource "databricks_default_namespace_setting" "default_namespace" {
  provider = databricks.workspace
  namespace {
    value = databricks_catalog.catalog.name
  }
}

resource "databricks_disable_legacy_access_setting" "disable_legacy_access" {
  provider = databricks.workspace
  disable_legacy_access {
    value = true
  }
}

resource "databricks_schema" "schema" {
  provider     = databricks.workspace
  for_each     = { for s in local.schemas : s.name => s }
  catalog_name = databricks_catalog.catalog.name
  name         = each.value.name
  owner        = data.databricks_group.admin_group.display_name
}

resource "databricks_volume" "shared_external_volume" {
  provider         = databricks.workspace
  name             = "vol_shared"
  catalog_name     = databricks_catalog.catalog.name
  schema_name      = "shared"
  volume_type      = "EXTERNAL"
  owner            = data.databricks_group.admin_group.display_name
  storage_location = databricks_external_location.external_location_shared.url
  depends_on       = [databricks_schema.schema, databricks_external_location.external_location_shared]
}

resource "databricks_cluster" "standard_single_cluster" {
  provider                = databricks.workspace
  cluster_name            = "standard_single"
  spark_version           = local.spark_version
  node_type_id            = local.node_type_id
  autotermination_minutes = 40
  data_security_mode      = "USER_ISOLATION"
  num_workers             = 1
  runtime_engine          = "STANDARD"
  is_pinned               = true
}

# Assign permissions to all workspace users for that cluster
resource "databricks_permissions" "cluster_usage_standard_single" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.standard_single_cluster.id
  access_control {
    group_name       = data.databricks_group.developer_group.display_name
    permission_level = "CAN_RESTART"
  }
}

resource "databricks_permissions" "cluster_admin_usage_standard_single" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.standard_single_cluster.id
  access_control {
    group_name       = data.databricks_group.admin_group.display_name
    permission_level = "CAN_MANAGE"
  }
}

# ML Ad_hoc processing cluster
resource "databricks_cluster" "ml_multi_cluster" {
  provider                = databricks.workspace
  cluster_name            = "ml_multi"
  spark_version           = local.spark_ml_version
  node_type_id            = local.node_type_id
  autotermination_minutes = 15
  data_security_mode      = "SINGLE_USER"
  runtime_engine          = "STANDARD"
  single_user_name        = data.databricks_group.developer_group.display_name
  is_pinned               = true
  autoscale {
    min_workers = 1
    max_workers = 4
  }
}

# Assign permissions to all workspace users for that cluster
resource "databricks_permissions" "cluster_usage_ml_multi" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.ml_multi_cluster.id
  access_control {
    group_name       = data.databricks_group.developer_group.display_name
    permission_level = "CAN_RESTART"
  }
}

resource "databricks_permissions" "cluster_admin_usage_ml_multi" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.ml_multi_cluster.id
  access_control {
    group_name       = data.databricks_group.admin_group.display_name
    permission_level = "CAN_MANAGE"
  }
}

# ML Ad_hoc processing cluster
resource "databricks_cluster" "ml_multi_gpu_cluster" {
  provider                = databricks.workspace
  cluster_name            = "ml_multi_gpu"
  spark_version           = local.spark_ml_version
  node_type_id            = "Standard_NC4as_T4_v3"
  autotermination_minutes = 15
  data_security_mode      = "SINGLE_USER"
  runtime_engine          = "STANDARD"
  single_user_name        = data.databricks_group.developer_group.display_name
  is_pinned               = true
  autoscale {
    min_workers = 1
    max_workers = 4
  }
}

# Assign permissions to all workspace users for that cluster
resource "databricks_permissions" "cluster_usage_ml_multi_gpu" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.ml_multi_gpu_cluster.id
  access_control {
    group_name       = data.databricks_group.developer_group.display_name
    permission_level = "CAN_RESTART"
  }
}

resource "databricks_permissions" "cluster_admin_usage_ml_multi_gpu" {
  provider   = databricks.workspace
  cluster_id = databricks_cluster.ml_multi_gpu_cluster.id
  access_control {
    group_name       = data.databricks_group.admin_group.display_name
    permission_level = "CAN_MANAGE"
  }
}

# Secret scope used by the workspace, backed by env's Azure Key Vault
resource "databricks_secret_scope" "secret_scope" {
  provider = databricks.workspace
  name     = "keyvault_scope"

  keyvault_metadata {
    resource_id = data.azurerm_key_vault.key_vault.id
    dns_name    = data.azurerm_key_vault.key_vault.vault_uri
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Allow project group to read from the secret scope
resource "databricks_secret_acl" "project_group_secret_read" {
  provider   = databricks.workspace
  principal  = data.databricks_group.developer_group.display_name
  permission = "READ"
  scope      = databricks_secret_scope.secret_scope.name
}
