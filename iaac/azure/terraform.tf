terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.42.0"
    }
  }
  backend "azurerm" {
    subscription_id      = "df10ab98-7ee0-4918-a53d-d10d5713442f"
    resource_group_name  = "rg-ecndlz-mgmt-d-plc-001"
    storage_account_name = "stecndlziaacstatedplc001"
    container_name       = "azure-state"
    key                  = "azure-state.tfstate"
  }
}