variable "environment" {
  description = "Abbrevation of the environment for naming purposes e.g. dev"
}

variable "project" {
  description = "Name of the project, used for naming purposes eg. ml"
}

variable "location" {
  description = "Location where the solution will be deployed eg. polandcentral"
}

variable "location_abbrv" {
  description = "Abbreviation of the location, used for naming purposes eg. plc"
}

variable "subscription_id" {
  description = "The subscription ID where the resources will be created"
}

variable "cidr" {
  description = "Network range for created virtual network."
}

variable "databricks_object_id" {
  description = "The object ID of the Databricks service principal in Azure AD."
}