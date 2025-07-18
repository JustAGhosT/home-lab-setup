# GitHub Secrets for Azure Deployment

This document explains the GitHub secrets required for deploying to Azure using GitHub Actions workflows.

## Required Secrets

Configure these secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `AZURE_CLIENT_ID` | Service principal client ID |
| `AZURE_CLIENT_SECRET` | Service principal client secret |
| `AZURE_TENANT_ID` | Your Azure tenant ID |
| `AZURE_CREDENTIALS` | Complete Azure credentials JSON |
| `GITHUB_TOKEN` | GitHub personal access token |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | API token for Static Web Apps (for static deployments) |
| `AZURE_WEBAPP_PUBLISH_PROFILE` | Publish profile for App Service (for appservice deployments) |

## Azure Service Principal Setup

To create the necessary service principal for GitHub Actions:

```bash
# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "github-actions-deployment" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

This command will output a JSON object that should be stored as the `AZURE_CREDENTIALS` secret in your GitHub repository.

## Setting Up Secrets in GitHub

1. Navigate to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Add each of the required secrets with their respective values

## Obtaining Secret Values

### Azure Subscription ID

```bash
az account show --query id -o tsv
```

### Azure Service Principal

```bash
# Create service principal and capture output
az ad sp create-for-rbac \
  --name "github-actions-deployment" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth > azure-credentials.json

# Extract values from the output
AZURE_CLIENT_ID=$(cat azure-credentials.json | jq -r .clientId)
AZURE_CLIENT_SECRET=$(cat azure-credentials.json | jq -r .clientSecret)
AZURE_TENANT_ID=$(cat azure-credentials.json | jq -r .tenantId)
AZURE_CREDENTIALS=$(cat azure-credentials.json)
```

### Static Web Apps API Token

This token is generated when you create a Static Web App in Azure. You can find it in the Azure Portal:

1. Navigate to your Static Web App resource
2. Go to "Overview" > "Manage deployment token"
3. Copy the token value

### App Service Publish Profile

1. Navigate to your App Service in the Azure Portal
2. Go to "Overview" > "Get publish profile"
3. Download the file and use its contents as the secret value

## Security Notes

- Never commit these secrets to your repository
- Rotate secrets periodically for better security
- Use the least privilege principle when creating service principals
- Consider using GitHub Environments for environment-specific secrets