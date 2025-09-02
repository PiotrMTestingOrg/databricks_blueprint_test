# Execute script to setup the storage account for Terraform state
# scripts/create_state_storage.ps1 -SubscriptionId "355f69b4-9fad-45c6-b881-2e7a4d376b18" -Environment "dev" -Location "germanywestcentral" -LocationAbbrv "gwc" -Project "ml"

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$LocationAbbrv,

    [Parameter(Mandatory = $true)]
    [string]$Project
)

$ResourceGroupName = "rg-${Project}-mgmt-${Environment}-${LocationAbbrv}-001"
$StorageAccountName = "st${Project}iaacstate${Environment}${LocationAbbrv}001"

az account set --subscription $SubscriptionId

# Create Resource Group
az group create --name $ResourceGroupName --location $Location

# Register storage resource provider

az provider register --namespace Microsoft.Storage

# Create storage account
az storage account create --name $StorageAccountName --resource-group $ResourceGroupName --location $Location --sku Standard_LRS --kind StorageV2

# Enable Blob Versioning
az storage account blob-service-properties update --resource-group $ResourceGroupName --account-name $StorageAccountName --enable-versioning true

# Create Storage Containers
az storage container create --name "azure-state" --account-name $StorageAccountName --auth-mode login
az storage container create --name "account-state" --account-name $StorageAccountName --auth-mode login
az storage container create --name "workspace-state" --account-name $StorageAccountName --auth-mode login

# Enable soft delete
az storage account blob-service-properties update --account-name $StorageAccountName --resource-group $ResourceGroupName --enable-delete-retention true --delete-retention-days 7