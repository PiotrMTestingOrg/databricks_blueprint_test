variable "environment" {
  description = "Abbrevation of the environment for naming purposes e.g. dev"
}

variable "project" {
  description = "Name of the project, used for naming purposes eg. ml"
}

variable "location_abbrv" {
  description = "Abbreviation of the location, used for naming purposes eg. plc"
}

variable "subscription_id" {
  description = "The subscription ID where the resources will be created"
}

variable "dbx_account_id" {
  description = "ID of the Databricks account."
}

variable "developer_group" {
  description = "Name of the developer group in Databricks"
}

variable "admin_group" {
  description = "Name of the admin group in Databricks"
}