# How to Deploy Websites with HomeLab

This guide explains how to deploy websites to Azure using the HomeLab environment.

## Overview

HomeLab provides a comprehensive solution for deploying websites to Azure, with support for both Static Web Apps and App Service. The system can automatically detect the appropriate deployment type based on your project structure.

## Deployment Methods

### Method 1: Using the HomeLab UI

1. Start the HomeLab environment:
   ```powershell
   Import-Module .\HomeLab.psd1
   Start-HomeLab
   ```

2. From the main menu, select "Website Deployment"

3. Choose one of the following options:
   - **Browse and Select Project**: Browse to your project folder and analyze its structure
   - **Deploy Static Website**: Deploy a static website (React, Angular, Vue, HTML/CSS/JS)
   - **Deploy App Service Website**: Deploy a dynamic website (Node.js, Python, .NET)
   - **Auto-Detect and Deploy Website**: Let HomeLab determine the best deployment type

4. Follow the prompts to provide:
   - Resource group name
   - Application name
   - Location
   - Custom domain (optional)
   - GitHub repository details (optional)

5. HomeLab will deploy your website and provide you with the deployment URL

### Method 2: Using PowerShell Directly

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
```

### Method 3: GitHub Actions Workflows

HomeLab can add GitHub workflow files to your project for automated CI/CD:

1. From the HomeLab UI, select "Website Deployment" > "Add GitHub Workflows"
2. Browse to your project folder
3. Select the deployment type (static, appservice, or auto)
4. Configure your custom domain
5. HomeLab will add the following files to your project:
   - `.github/workflows/deploy-azure.yml` - For single environment deployment
   - `.github/workflows/deploy-multi-env.yml` - For multi-environment deployment

Once these files are added, you can deploy your website directly from GitHub:

1. Push your project to GitHub
2. Navigate to the Actions tab in your GitHub repository
3. Select one of the workflows
4. Click "Run workflow"
5. Fill in the required parameters
6. GitHub Actions will deploy your website to Azure

## Choosing the Right Deployment Type

### Static Web App

**Use Cases**:
- React/Vue/Angular apps
- Static HTML/CSS/JS sites
- JAMstack applications
- Documentation sites
- Blogs

**Characteristics**:
- No server-side rendering
- No backend APIs
- No database connections
- Static files only

### App Service

**Use Cases**:
- Node.js/Express applications
- Python/Django/Flask apps
- .NET applications
- PHP applications
- Applications with APIs

**Characteristics**:
- Server-side rendering
- Backend APIs
- Database connections
- Dynamic content

To see a detailed comparison, use the "Show Deployment Type Info" option in the HomeLab UI.

## Custom Domain Configuration

After deployment, you'll need to configure your DNS provider with the appropriate records:

### For Static Web Apps

```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurestaticapps.net
```

### For App Service

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
Value: {verification-id-from-azure}
```

## Multi-Environment Deployment

HomeLab supports deploying to multiple environments (dev, staging, prod):

1. From the HomeLab UI, select "Website Deployment" > "Add GitHub Workflows"
2. Add the multi-environment workflow to your project
3. Push your project to GitHub
4. Run the "Deploy to Multiple Environments" workflow
5. Set environments: "dev,staging,prod"
6. Set base subdomain: "myapp"

This will deploy your website to:
- myapp-dev.yourdomain.com
- myapp-staging.yourdomain.com
- myapp.yourdomain.com

## Required GitHub Secrets

If using GitHub Actions, you'll need to configure these secrets:

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

See [GitHub Secrets Documentation](GITHUB-SECRETS.md) for details on how to set these up.

## Troubleshooting

### Common Issues

#### Resource already exists
- Use a different resource name
- Delete the existing resource first

#### DNS not propagating
- Wait 24-48 hours for DNS propagation
- Check DNS records with nslookup

#### SSL certificate issues
- Ensure DNS records are correct
- Wait for automatic certificate provisioning

#### GitHub Actions failing
- Verify all secrets are set correctly
- Check Azure permissions

## Additional Resources

- [Website Deployment Guide](WEBSITE-DEPLOYMENT.md) - Detailed information about deployment types
- [GitHub Secrets Guide](GITHUB-SECRETS.md) - How to set up GitHub secrets for deployment