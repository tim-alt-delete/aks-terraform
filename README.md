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

# Create Azure Service Principal

## (Option 1) CI/CD Federated Identity / OIDC
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
  --role Contributor \
  --scope /subscriptions/$SUB_ID/resourceGroups/rg-tfm-backend-test

# or a single subscription (broader permissions)
# az role assignment create \
#   --assignee $APP_ID \
#   --role Contributor \
#   --scope /subscriptions/$SUB_ID

# Add github OIDC federation
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-main",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-alt-delete/aks-terraform:ref:refs/heads/main",
    "audiences":["api://AzureADTokenExchange"]
  }'

# Federate for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-pr",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-alt-delete/aks-terraform:pull_request",
    "audiences":["api://AzureADTokenExchange"]
  }'

# Add production environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name":"github-prod",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:tim-alt-delete/aks-terraform:pull_request:environment:production",
    "audiences":["api://AzureADTokenExchange"]
  }'
```


## (Option 2) 
Simpler initially, but you must store/rotate secrets.

```bash
az ad sp create-for-rbac \
  --name "tofu-ci" \
  --role Contributor \
  --scopes /subscriptions/<SUB_ID> \
  --json-auth
```

Store these secrets securely. This outputs:
```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

## Verify Auth Works
```bash
export ARM_CLIENT_ID=...
export ARM_CLIENT_SECRET=...
export ARM_SUBSCRIPTION_ID=...
export ARM_TENANT_ID=...

tofu plan
```

Store these secrets securely.

# Private AKS Cluster Example

https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/latest/examples/private# aks-terraform
