# Azure Deployment Guide

## Overview

This project is configured for automatic deployment to Azure with custom subdomains. The system intelligently chooses between Azure Static Web Apps and Azure App Service based on your application requirements.

## Quick Start

### 1. Prerequisites

- Azure subscription with contributor access
- GitHub repository
- Domain name (optional, for custom domains)

### 2. Setup GitHub Secrets

Add these secrets to your GitHub repository:

```
AZURE_SUBSCRIPTION_ID      # Your Azure subscription ID
AZURE_CLIENT_ID            # Service principal client ID
AZURE_CLIENT_SECRET        # Service principal client secret
AZURE_TENANT_ID            # Your Azure tenant ID
AZURE_CREDENTIALS          # Complete Azure credentials JSON
GITHUB_TOKEN               # GitHub personal access token
```

For Static Web Apps, also add:
```
AZURE_STATIC_WEB_APPS_API_TOKEN  # API token for Static Web Apps
```

For App Service, also add:
```
AZURE_WEBAPP_PUBLISH_PROFILE     # Publish profile for App Service
```

### 3. Configure Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/{subscription-id}

# Output will provide the credentials needed for GitHub secrets
```

## Deployment Options

### Option 1: GitHub Actions Workflow

1. Navigate to your GitHub repository's Actions tab
2. Select one of the available workflows:
   - "Deploy to Azure with Custom Domain" - for single environment deployment
   - "Deploy to Multiple Environments" - for multi-environment deployment
3. Click "Run workflow"
4. Fill in the required parameters:
   - Deployment Type: static/appservice/auto
   - Environment: dev/staging/prod
   - Subdomain: Your desired subdomain
   - Custom Domain: Your domain (e.g., yourdomain.com)

### Option 2: Manual Deployment via PowerShell

```powershell
# Deploy static web app
Deploy-Website `
  -DeploymentType static `
  -ResourceGroup "rg-myapp" `
  -AppName "myapp-prod" `
  -SubscriptionId "{your-subscription-id}" `
  -CustomDomain "yourdomain.com" `
  -Subdomain "myapp"

# Deploy app service
Deploy-Website `
  -DeploymentType appservice `
  -ResourceGroup "rg-api" `
  -AppName "api-prod" `
  -SubscriptionId "{your-subscription-id}" `
  -CustomDomain "yourdomain.com" `
  -Subdomain "api"
```

## Decision Matrix: Static Web Apps vs App Service

| Feature | Static Web Apps | App Service |
|---------|----------------|-------------|
| Best For | Static sites, SPAs, JAMstack | Dynamic web applications |
| Examples | React, Vue, Angular, HTML/CSS/JS | Node.js, Python/Django, .NET, PHP |
| Server-side Processing | ❌ No | ✅ Yes |
| Database Connections | ❌ No | ✅ Yes |
| API Endpoints | ⚠️ Via Azure Functions | ✅ Built-in |
| Custom Runtimes | ❌ No | ✅ Yes |
| Global CDN | ✅ Built-in | ⚠️ Optional |
| Auto SSL | ✅ Free | ✅ Free |
| Cost | Free - $9/month | $13+ per month |
| Scaling | Automatic | Manual/Auto |

## Custom Domain Configuration

### DNS Records Required

After deployment, add these DNS records:

For Static Web Apps:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurestaticapps.net
```

For App Service:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurewebsites.net
```

### Domain Verification

Both services require domain verification:
```
Type: TXT
Name: asuid.{subdomain}
Value: {verification-id}
```

## Environment Configuration

### Development Environment
- Subdomain: {app-name}-dev.{domain}
- Resource Group: rg-{app-name}-dev
- SKU: Free tier

### Staging Environment
- Subdomain: {app-name}-staging.{domain}
- Resource Group: rg-{app-name}-staging
- SKU: Basic tier

### Production Environment
- Subdomain: {app-name}.{domain}
- Resource Group: rg-{app-name}-prod
- SKU: Standard tier

## Troubleshooting

### Common Issues

### Resource already exists
- Use --force-deployment flag
- Or delete existing resources first

### DNS not propagating
- Wait 24-48 hours for DNS propagation
- Check DNS records with nslookup

### SSL certificate issues
- Ensure DNS records are correct
- Wait for automatic certificate provisioning

### GitHub Actions failing
- Verify all secrets are set correctly
- Check Azure permissions

### Verification Commands

```bash
# Check DNS propagation
nslookup {subdomain}.{domain}

# Verify SSL certificate
openssl s_client -connect {subdomain}.{domain}:443

# Check Azure resources
az resource list --resource-group {resource-group}
```

## Advanced Usage

### Multi-Environment Deployment

Use the matrix workflow to deploy to multiple environments:
```
environments: "dev,staging,prod"
base_subdomain: "myapp"
```

### Environment Variables

Set environment-specific variables:
```bash
az webapp config appsettings set \
  --name {app-name} \
  --resource-group {resource-group} \
  --settings NODE_ENV=production
```

## Security Best Practices

- Use Service Principal with minimal permissions
- Store secrets securely in GitHub
- Enable Azure Key Vault integration
- Use managed identities where possible
- Regularly rotate access tokens

## Cost Optimization

### Static Web Apps
- Use free tier for development
- Enable compression and caching
- Monitor bandwidth usage

### App Service
- Use appropriate SKU for workload
- Enable auto-scaling rules
- Consider reserved instances for production

## Support and Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)