# Website Deployment Guide

This guide explains how to deploy websites to Azure using the HomeLab environment.

## Deployment Types

### Static Web App

**Description**: Use for static sites, SPAs, JAMstack apps

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

**Azure Resources**:
- Azure Static Web Apps
- Azure CDN (optional)
- Azure DNS (for custom domains)

**Pricing**: Free tier available, pay-as-you-go

**Auto-detect Files**:
- index.html
- build/index.html
- dist/index.html
- public/index.html

### App Service

**Description**: Use for dynamic web applications with server-side logic

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

**Azure Resources**:
- Azure App Service
- App Service Plan
- Azure Application Insights (optional)
- Azure DNS (for custom domains)

**Pricing**: Starts from Basic tier, various plans available

**Auto-detect Files**:
- package.json (with server frameworks)
- requirements.txt
- wsgi.py
- asgi.py
- manage.py
- *.csproj
- Program.cs

## Decision Matrix

| Question | Static Web App | App Service |
|----------|---------------|-------------|
| Does your app need server-side processing? | No | Yes |
| Do you need to connect to databases? | No | Yes |
| Do you have API endpoints? | No (or use Azure Functions) | Yes |
| Is your content pre-built/static? | Yes | No |
| Do you need custom runtime environments? | No | Yes |

## Environments

| Environment | Description | Subdomain Suffix | Azure Location | SKU |
|-------------|-------------|------------------|----------------|-----|
| dev | Development environment | -dev | eastus | Free |
| staging | Staging environment | -staging | eastus | Basic |
| prod | Production environment | (none) | eastus | Standard |

## Custom Domain Configuration

### DNS Records

**CNAME Record**:
- Description: Points subdomain to Azure service
- Format: subdomain.yourdomain.com -> azure-service.net

**TXT Record**:
- Description: Domain verification record
- Format: asuid.subdomain.yourdomain.com -> verification-id

### SSL Certificates

- Static Web Apps: Automatic SSL certificates
- App Service: Automatic SSL certificates with custom domains

## Required GitHub Secrets

Configure these secrets in your GitHub repository:

```
AZURE_SUBSCRIPTION_ID      # Your Azure subscription ID
AZURE_CLIENT_ID            # Service principal client ID
AZURE_CLIENT_SECRET        # Service principal client secret
AZURE_TENANT_ID            # Your Azure tenant ID
AZURE_CREDENTIALS          # Complete Azure credentials JSON
GITHUB_TOKEN               # GitHub personal access token
```

## Azure Service Principal Setup

```bash
# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "github-actions-deployment" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

## Usage Examples

### Manual Deployment

**Deploy a React Application**:

```powershell
Deploy-Website -DeploymentType static -ResourceGroup "rg-portfolio" -AppName "portfolio-prod" -SubscriptionId "abc123" -CustomDomain "johndoe.com" -Subdomain "portfolio"
```
Result: <https://portfolio.johndoe.com>

**Deploy a Node.js API**:

```powershell
Deploy-Website -DeploymentType appservice -ResourceGroup "rg-api" -AppName "backend-api" -SubscriptionId "abc123" -CustomDomain "mycompany.com" -Subdomain "api"
```
Result: <https://api.mycompany.com>

### GitHub Actions Deployment

1. Navigate to your repository's Actions tab
2. Select "Deploy to Azure with Custom Domain"
3. Click "Run workflow"
4. Configure parameters:
   - Deployment Type: static/appservice/auto
   - Environment: dev/staging/prod
   - Subdomain: Your desired subdomain
   - Custom Domain: Your domain (e.g., liquidmesh.ai)

### Multi-Environment Deployment

For deploying to multiple environments simultaneously:

1. Select "Deploy to Multiple Environments" workflow
2. Set environments: "dev,staging,prod"
3. Set base subdomain: "myapp"

Results:
- myapp-dev.yourdomain.com
- myapp-staging.yourdomain.com
- myapp.yourdomain.com

## DNS Configuration

After deployment, configure your DNS provider with the appropriate records:

**For Static Web Apps**:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurestaticapps.net
```

**For App Service**:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurewebsites.net
```

**Domain Verification (Required)**:
```
Type: TXT
Name: asuid.{subdomain}
Value: {verification-id-from-azure}
```

## Key Features

- ✅ Intelligent Auto-Detection - Automatically chooses the best deployment type
- ✅ Custom Subdomain Support - Deploy to your own domain with subdomains
- ✅ Multi-Environment Deployment - Deploy to dev, staging, and prod simultaneously
- ✅ GitHub Actions Integration - Automated CI/CD workflows
- ✅ SSL Certificate Automation - Free SSL certificates for all deployments
- ✅ Cost Optimization - Choose the most cost-effective Azure service

## Environment-Specific Configuration

- **Development**: Free tier, -dev suffix, debug logging
- **Staging**: Basic tier, -staging suffix, production-like config
- **Production**: Standard tier, no suffix, performance optimized