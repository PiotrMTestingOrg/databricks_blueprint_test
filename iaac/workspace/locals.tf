locals {
  adls = {
    metastore = provider::azurerm::parse_resource_id(data.azurerm_key_vault_secret.secret_adls_metastore_id.value)["resource_name"]
    shared    = provider::azurerm::parse_resource_id(data.azurerm_key_vault_secret.secret_adls_shared_id.value)["resource_name"]
  }

  schemas = [
    {
      name = "shared"
    }
  ]
}