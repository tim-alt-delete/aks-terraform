#!/bin/bash

# This script creates an Azure Storage Account
# to store the Terraform backend. This is where
# Terraform stores its state file.
ENV="test"
LOCATION="eastus"
SUBSCRIPTION=""
RESOURCE_GROUP_NAME="rg-tfm-backend-${ENV}"
# Note: Storage Account names must be globally unique to Azure
STORAGE_ACCOUNT_NAME="satfmbackend${ENV}${RANDOM}"
TAGS="env=${ENV} source=azure-cli project=learn"

# Create Resource Group
az group create \
	--subscription $SUBSCRIPTION \
    --location $LOCATION \
    --name $RESOURCE_GROUP_NAME \
    --tags $TAGS

# Create Storage Account
# Note: Storage Account names must be globally unique to Azure
az storage account create \
	--subscription $SUBSCRIPTION \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STORAGE_ACCOUNT_NAME \
    --access-tier hot \
    --allow-blob-public-access false \
    --encryption-services blob \
    --sku STANDARD_ZRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --https-only true \
    --enable-hierarchical-namespace false \
    --allow-shared-key-access false

# enable blob container versioning
az storage account blob-service-properties update \
    --enable-versioning true \
    --resource-group $RESOURCE_GROUP_NAME \
    --account-name $STORAGE_ACCOUNT_NAME

# enable container level delete retention (soft delete)
az storage account blob-service-properties update \
    --enable-container-delete-retention true \
    --container-delete-retention-days 7 \
    --account-name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME

# create blob container
az storage container create \
    --name tfmstate \
    --account-name $STORAGE_ACCOUNT_NAME \
    --account-key $STORAGE_ACCOUNT_ACCESS_KEY

# Add the following to your main.tf file (uncommented)
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-tfm-backend"
#     storage_account_name = "satfmbackend"
#     container_name       = "tfmstate"
#     key                  = "test.terraform.tfstate"
#   }
# }