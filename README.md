# Dependencies

## Mise
Install Mise
```bash
brew install mise # mac
curl https://mise.run | sh # linux
```

Install common packages
```bash
# To use pipx packages with mise, you need to install pipx first:
mise use pipx@latest
mise use opentofu
mise use kubectl
mise use helm
mise use azure-cli
mise use terraform-docs
```

# CI/CD Federated Identity / OIDC

## Create Azure App and Service Principal
This is the modern approach for:

* GitHub Actions
* GitLab CI
* Azure DevOps
* Terraform Cloud

Use this to give github actions permission to deploy resources in azure:

```bash
# create app and service principal
az ad app create \
  --display-name "tofu-ci"

APP_ID=$(az ad app list \
  --display-name "tofu-ci" \
  --query "[0].appId" -o tsv)

az ad sp create --id $APP_ID

SUB_ID=$(az account show --query id -o tsv)

# grant contributor to a single resource group
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUB_ID/resourceGroups/rg-private-aks-test


# Also don't forget to grant permission to TF Backend
az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$SUB_ID/resourceGroups/rg-tfm-backend-test/providers/Microsoft.Storage/storageAccounts/satfmbackendtest0123/blobServices/default/containers/tfmstate

# or a single subscription (broader permissions)
# az role assignment create \
#   --assignee $APP_ID \
#   --role Contributor \
#   --scope /subscriptions/$SUB_ID

# Verify the role assignments
az role assignment list \
  --assignee $APP_ID \      
  --all \
--output table

```

Store the following as github secrets:

* `AZURE_CLIENT_ID`
* `AZURE_SUBSCRIPTION_ID`
* `AZURE_TENANT_ID`

## Create OIDC Federation

```bash
# Add github OIDC federation
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-main",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-pulliam/aks-terraform:ref:refs/heads/main",
    "audiences":["api://AzureADTokenExchange"]
  }'

# Federate for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-pr",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-pulliam/aks-terraform:pull_request",
    "audiences":["api://AzureADTokenExchange"]
  }'

# Add production environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-prod",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-pulliam/aks-terraform:pull_request:environment:production",
    "audiences":["api://AzureADTokenExchange"]
  }'
```

# Private Azure Network
https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization

You will need:
* Github Organization (requires team plan)
* Github Personal Access Token Classic to get Github DatabaseID

## Save Network Security Group
https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#configuring-your-azure-resources

To allow github to talk to a private Azure network, first save the nsg to a file `actions-nsg-deployment.bicep`. 


## Get Github DatabaseID
https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#2-use-a-script-to-configure-your-azure-resources

You will need to create a Github Personal Access Token (Classic). 

https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic

Give your token `read:org` permissions to query graphql for your github DatabaseID. Replace `BEARER_TOKEN` with your PAT.

```bash
curl -H "Authorization: Bearer BEARER_TOKEN" -X POST \
  -d '{ "query": "query($login: String!) { organization (login: $login) { login databaseId } }" ,
        "variables": {
          "login": "ORGANIZATION_NAME"
        }
      }' \
https://api.github.com/graphql
```

## Create Azure Private Network Resources
https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#2-use-a-script-to-configure-your-azure-resources 

Save the script in the same location you saved the NSG template file.

The script will output `GitHubId`. Save the value for the next step.


# Create Network Configuration in Github Org

https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#1-add-a-new-network-configuration-for-your-organization

# Private AKS Cluster Example

https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/latest/examples/private# aks-terraform


# Additional Resources

Github / Azure Authentication:
https://learn.microsoft.com/en-us/azure/developer/github/github-actions

OIDC 
https://learn.microsoft.com/en-us/azure/developer/github/github-actions

Terraform examples:
https://github.com/Azure/actions-workflow-samples/tree/master/Terraform

https://github.com/Azure/terraform/tree/master/quickstart

Private networking with GitHub-hosted runners
https://docs.github.com/en/actions/concepts/runners/private-networking

https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization

jobs:
  apply:
    environment:
      name: production