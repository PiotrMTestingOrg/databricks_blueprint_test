# Create regional metastore
resource "databricks_metastore" "metastore" {
  provider = databricks.accounts
  name     = "metastore_${var.region}"
  region   = var.region
  owner    = var.admin_group
}