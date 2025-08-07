# HomeLab.Web Module

This module provides functionality for deploying and managing websites in Azure as part of the HomeLab environment.

## Features

- Deploy static websites using Azure Static Web Apps
- Deploy dynamic websites using Azure App Service
- Auto-detect project type and deploy accordingly
- Configure custom domains for websites
- Manage website deployments
- Add GitHub workflow files for CI/CD

## Deployment Types

### Static Web App

**Use Cases**: React/Vue/Angular apps, static HTML/CSS/JS sites, JAMstack applications, documentation sites, blogs

**Characteristics**: No server-side rendering, no backend APIs, no database connections, static files only

**Azure Resources**: Azure Static Web Apps, Azure CDN (optional), Azure DNS (for custom domains)

**Pricing**: Free tier available, pay-as-you-go

### App Service

**Use Cases**: Node.js/Express applications, Python/Django/Flask apps, .NET applications, PHP applications, applications with APIs

**Characteristics**: Server-side rendering, backend APIs, database connections, dynamic content

**Azure Resources**: Azure App Service, App Service Plan, Azure Application Insights (optional), Azure DNS (for custom domains)

**Pricing**: Starts from Basic tier, various plans available

## Functions

### Public Functions

- `Deploy-Website`: Deploys a website to Azure using either Static Web Apps or App Service
- `Configure-CustomDomainStatic`: Configures a custom domain for a Static Web App
- `Configure-CustomDomainAppService`: Configures a custom domain for an App Service
- `Add-GitHubWorkflows`: Adds GitHub workflow files for automatic deployment
- `Show-DeploymentTypeInfo`: Displays information about deployment types
- `Select-ProjectFolder`: Opens a folder browser dialog to select a project folder

## Usage

```powershell
# Import the module
Import-Module HomeLab.Web

# Deploy a static website
Deploy-Website -DeploymentType static -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Deploy an app service website
Deploy-Website -DeploymentType appservice -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Auto-detect and deploy a website
Deploy-Website -DeploymentType auto -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000" -ProjectPath "C:\Projects\MyWebsite"

# Configure a custom domain
Deploy-Website -DeploymentType static -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000" -CustomDomain "example.com" -Subdomain "www"

# Add GitHub workflow files
Add-GitHubWorkflows -ProjectPath "C:\Projects\MyWebsite" -DeploymentType "auto" -CustomDomain "example.com"

# Show deployment type information
Show-DeploymentTypeInfo
```

## GitHub Workflows

This module can add GitHub workflow files to your project for automated CI/CD:

- `deploy-azure.yml`: Deploys to a single environment
- `deploy-multi-env.yml`: Deploys to multiple environments (dev, staging, prod)

See [GitHub Secrets Documentation](../../docs/GITHUB-SECRETS.md) for required secrets.

## Dependencies

- HomeLab.Core
- HomeLab.Azure
- Az PowerShell Module

## Documentation

For detailed information, see:
- [Website Deployment Guide](../../docs/WEBSITE-DEPLOYMENT.md) - Detailed information about deployment types
- [How to Deploy Websites](../../docs/HOW-TO-DEPLOY-WEBSITES.md) - Step-by-step guide on deploying websites
- [GitHub Secrets Guide](../../docs/GITHUB-SECRETS.md) - How to set up GitHub secrets for deployment