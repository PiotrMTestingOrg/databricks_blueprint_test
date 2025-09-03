variable "dbx_account_id" {
  description = "ID of the Databricks account."
}

variable "region" {
  description = "Azure region where the Databricks metastore is located."
}

variable "admin_group" {
  description = "Name of the admin group for the project."
}

variable "subscription_id" {
  description = "The subscription ID where the resources will be created"
}