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

  # Cluster properties
  spark_version    = "16.4.x-scala2.13"
  spark_ml_version = "16.4.x-cpu-ml-scala2.13"
  node_type_id     = "Standard_D4ds_v5"
}