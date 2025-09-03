resource "azurerm_resource_group" "rg_storage" {
  name     = "rg-${var.project}-storage-${var.environment}-${var.location_abbrv}-001"
  location = var.location
}

resource "azurerm_resource_group" "rg_shared" {
  name     = "rg-${var.project}-shared-${var.environment}-${var.location_abbrv}-001"
  location = var.location
}

resource "azurerm_resource_group" "rg_network" {
  name     = "rg-${var.project}-network-${var.environment}-${var.location_abbrv}-001"
  location = var.location
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "kv-${var.project}-${var.environment}-${var.location_abbrv}-001"
  location                    = azurerm_resource_group.rg_shared.location
  resource_group_name         = azurerm_resource_group.rg_shared.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  rbac_authorization_enabled  = true

  sku_name = "standard"
}

# Create Storage account for Databricks Metastore
resource "azurerm_storage_account" "adls_metastore" {
  name                            = "st${var.project}${var.environment}${var.location_abbrv}001"
  resource_group_name             = azurerm_resource_group.rg_storage.name
  location                        = azurerm_resource_group.rg_storage.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  default_to_oauth_authentication = true
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"
  is_hns_enabled                  = true
}

# Create storage containers
resource "azurerm_storage_container" "adls_metastore_container" {
  name                  = "metastore"
  storage_account_id    = azurerm_storage_account.adls_metastore.id
  container_access_type = "private"
}

# Create Storage Account for input Data
resource "azurerm_storage_account" "adls_shared" {
  name                            = "st${var.project}${var.environment}${var.location_abbrv}002"
  resource_group_name             = azurerm_resource_group.rg_storage.name
  location                        = azurerm_resource_group.rg_storage.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  default_to_oauth_authentication = true
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"
  is_hns_enabled                  = true
}

resource "azurerm_storage_container" "adls_shared_container" {
  for_each              = toset(local.adls_containers)
  name                  = lower(replace(each.value, " ", "-"))
  storage_account_id    = azurerm_storage_account.adls_shared.id
  container_access_type = "private"
}

resource "azurerm_databricks_workspace" "workspace" {
  name                        = "dbw-${var.project}-${var.environment}-${var.location_abbrv}-001"
  resource_group_name         = azurerm_resource_group.rg_shared.name
  location                    = azurerm_resource_group.rg_shared.location
  sku                         = "premium"
  managed_resource_group_name = "dbw-mgnd-${var.project}-${var.environment}-${var.location_abbrv}-001"

  custom_parameters {
    no_public_ip                                         = true
    public_subnet_name                                   = azurerm_subnet.subnet_host.name
    private_subnet_name                                  = azurerm_subnet.subnet_container.name
    virtual_network_id                                   = azurerm_virtual_network.virtual_network.id
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.host_association.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.container_association.id
  }

}

resource "azurerm_databricks_access_connector" "access_connector" {
  name                = "dbac-${var.project}-${var.environment}-${var.location_abbrv}-001"
  resource_group_name = azurerm_resource_group.rg_shared.name
  location            = azurerm_resource_group.rg_shared.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adls_metastore_connector_data_contributor" {
  scope                = azurerm_storage_account.adls_metastore.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.access_connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "adls_shared_connector_data_contributor" {
  scope                = azurerm_storage_account.adls_shared.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.access_connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "key_vault_connector_secrets_officer" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_databricks_access_connector.access_connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "key_vault_databricks_secrets_officer" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.databricks_object_id
}

resource "azurerm_role_assignment" "key_vault_spn_secrets_officer" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployment_identity_id
}

resource "azurerm_key_vault_secret" "secret_workspace_id" {
  name         = "databricks-workspace-id"
  value        = azurerm_databricks_workspace.workspace.id
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.key_vault_spn_secrets_officer]
}

resource "azurerm_key_vault_secret" "secret_access_connector_id" {
  name         = "databricks-access-connector-id"
  value        = azurerm_databricks_access_connector.access_connector.id
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.key_vault_spn_secrets_officer]
}

resource "azurerm_key_vault_secret" "secret_adls_metastore_id" {
  name         = "adls-metastore-id"
  value        = azurerm_storage_account.adls_metastore.id
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.key_vault_spn_secrets_officer]
}

resource "azurerm_key_vault_secret" "secret_adls_shared_id" {
  name         = "adls-shared-id"
  value        = azurerm_storage_account.adls_shared.id
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.key_vault_spn_secrets_officer]
}