# Multi-Platform Website Deployment Guide

This comprehensive guide explains how to deploy websites to multiple cloud platforms using the HomeLab environment, including Azure, Vercel, Netlify, AWS, and Google Cloud.

## 🚀 Supported Platforms

### Azure (First-Class Citizen)
- **Static Web Apps**: Perfect for JAMstack and static sites
- **App Service**: Full-stack applications with server-side logic
- **Auto-Detection**: Intelligent project type detection
- **Resource Management**: Comprehensive Azure resource handling

### Vercel
- **Optimized for**: Next.js, React, Vue, Angular
- **Features**: Automatic framework detection, edge functions
- **Global CDN**: Lightning-fast deployments worldwide

### Netlify
- **JAMstack Optimized**: Perfect for static sites and SPAs
- **Features**: Form handling, serverless functions, continuous deployment
- **Build System**: Automatic build and deployment from Git

### AWS
- **S3 + CloudFront**: Scalable static hosting with global CDN
- **Cost-Effective**: Pay only for what you use
- **Enterprise Ready**: Full AWS ecosystem integration

### Google Cloud
- **Cloud Run**: Serverless containers for dynamic applications
- **App Engine**: Platform-as-a-Service for traditional web apps
- **Global Infrastructure**: Google's worldwide network

## 📋 Deployment Types

### Static Deployment
**Description**: Use for static sites, SPAs, JAMstack apps

**Use Cases**:
- React/Vue/Angular apps
- Static HTML/CSS/JS sites
- JAMstack applications
- Documentation sites
- Blogs
- Portfolio websites

**Characteristics**:
- No server-side rendering
- No backend APIs
- No database connections
- Static files only

**Auto-detect Files**:
- `index.html`
- `build/index.html`
- `dist/index.html`
- `public/index.html`

### App Service/Backend Deployment
**Description**: Use for dynamic web applications with server-side logic

**Use Cases**:
- Node.js/Express applications
- Python/Django/Flask apps
- .NET applications
- PHP applications
- Applications with APIs
- Full-stack applications

**Characteristics**:
- Server-side rendering
- Backend APIs
- Database connections
- Dynamic content

**Auto-detect Files**:
- `package.json` (with server frameworks like Express, Koa, Fastify)
- `requirements.txt`, `Pipfile`, `setup.py`
- `wsgi.py`, `asgi.py`, `manage.py`
- `*.csproj`, `Program.cs`, `Startup.cs`

### Auto-Detection
**Description**: Let the system automatically determine the best deployment type

**Features**:
- Analyzes project structure
- Detects framework indicators
- Chooses optimal deployment strategy
- Provides intelligent recommendations

## 🎯 Platform Decision Matrix

| Feature              | Azure             | Vercel            | Netlify           | AWS             | Google Cloud  |
| -------------------- | ----------------- | ----------------- | ----------------- | --------------- | ------------- |
| **Static Sites**     | ✅ Static Web Apps | ✅ Optimized       | ✅ JAMstack        | ✅ S3+CloudFront | ✅ Cloud Run   |
| **Full-Stack Apps**  | ✅ App Service     | ✅ Edge Functions  | ✅ Serverless      | ✅ ECS/Lambda    | ✅ App Engine  |
| **Auto-Detection**   | ✅                 | ✅                 | ✅                 | ✅               | ✅             |
| **Custom Domains**   | ✅                 | ✅                 | ✅                 | ✅               | ✅             |
| **SSL Certificates** | ✅ Auto            | ✅ Auto            | ✅ Auto            | ✅ Auto          | ✅ Auto        |
| **Global CDN**       | ✅                 | ✅                 | ✅                 | ✅               | ✅             |
| **Git Integration**  | ✅                 | ✅                 | ✅                 | ✅               | ✅             |
| **Cost**             | Pay-as-you-go     | Free tier + usage | Free tier + usage | Pay-as-you-go   | Pay-as-you-go |

## 🔧 Platform-Specific Functions

### Deploy-Azure
#### Comprehensive Azure deployment with auto-detection

```powershell
Deploy-Azure -AppName "my-app" -ResourceGroup "my-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -DeploymentType "auto" -ProjectPath "C:\Projects\my-app"
```

**Features**:
- Static Web Apps and App Service support
- Resource group management
- Subscription context handling
- Custom domain configuration
- GitHub integration

### Deploy-Vercel
#### Vercel deployment with framework optimization

```powershell
Deploy-Vercel -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -VercelToken "your-token"
```

**Features**:
- Automatic framework detection
- Edge function support
- Global CDN deployment
- Environment variable management

### Deploy-Netlify
#### Netlify deployment for JAMstack applications

```powershell
Deploy-Netlify -AppName "my-jamstack-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -NetlifyToken "your-token"
```

**Features**:
- JAMstack optimization
- Form handling setup
- Serverless function deployment
- Continuous deployment from Git

### Deploy-AWS
#### AWS deployment with S3 and CloudFront

```powershell
Deploy-AWS -AppName "my-static-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -AwsRegion "us-east-1"
```

**Features**:
- S3 static hosting
- CloudFront CDN configuration
- Cost-effective scaling
- AWS CLI integration

### Deploy-GoogleCloud
#### Google Cloud deployment with Cloud Run and App Engine

```powershell
Deploy-GoogleCloud -AppName "my-app" -ProjectPath "C:\Projects\my-app" -Location "us-central1" -GcpProject "my-project" -DeploymentType "cloudrun"
```

**Features**:
- Cloud Run serverless containers
- App Engine platform-as-a-service
- Automatic Dockerfile generation
- Global Google infrastructure

## 🎨 Progress Tracking & User Experience

### Step-by-Step Progress Indicators
All deployment functions include comprehensive progress tracking:

```powershell
Step 1/6: Checking Azure PowerShell prerequisites...
Step 2/6: Setting Azure subscription...
Step 3/6: Creating resource group...
Step 4/6: Determining deployment type...
Step 5/6: Deploying to Azure...
Step 6/6: Configuring custom domain...
```

### AI-Powered Repository Suggestions
Intelligent repository scoring algorithm considers:
- **Language Detection**: Identifies primary programming language
- **Description Keywords**: Analyzes repository descriptions
- **Name Patterns**: Recognizes common naming conventions
- **Recent Activity**: Considers recent commits and updates
- **Repository Size**: Evaluates project complexity
- **Stars and Forks**: Community engagement indicators

### Consistent Return Values
All deployment functions return standardized information:

```powershell
@{
    Success = $true
    DeploymentUrl = "https://my-app.azurewebsites.net"
    AppName = "my-app"
    Platform = "Azure"
    Service = "Static Web Apps" # or "App Service"
    Region = "westeurope"
    ResourceGroup = "my-rg"
    CustomDomain = "example.com"
}
```

## 🌍 Environments & Naming Conventions

### Environment-Specific Configuration

| Environment | Description             | Subdomain Suffix | Location          | Pricing Tier     |
| ----------- | ----------------------- | ---------------- | ----------------- | ---------------- |
| dev         | Development environment | -dev             | Platform-specific | Free/Basic       |
| staging     | Staging environment     | -staging         | Platform-specific | Basic/Standard   |
| prod        | Production environment  | (none)           | Platform-specific | Standard/Premium |

### Resource Naming Convention
All platforms follow the consistent naming pattern:
```
[env]-[regionabbreviation]-[typeabbreviation]-project
```

**Examples**:
- `dev-eus-ver-myapp` (Development, East US, Vercel)
- `prod-weu-aws-myapp` (Production, West Europe, AWS)
- `staging-use-gcp-myapp` (Staging, US East, Google Cloud)

## 🔐 Authentication & Security

### Platform-Specific Authentication

#### Azure
- **OIDC Federation** (Recommended): Password-less authentication
- **Service Principal**: Traditional Azure authentication
- **Managed Identity**: Azure-native identity management

#### Vercel
- **Personal Access Token**: API-based authentication
- **OAuth Integration**: GitHub/GitLab integration
- **Team Tokens**: Organization-level access

#### Netlify
- **Personal Access Token**: API-based authentication
- **OAuth Integration**: Git provider integration
- **Site Tokens**: Site-specific deployment tokens

#### AWS
- **AWS CLI**: Standard AWS authentication
- **IAM Roles**: Role-based access control
- **Access Keys**: Programmatic access

#### Google Cloud
- **gcloud CLI**: Standard GCP authentication
- **Service Accounts**: Application-level authentication
- **OAuth 2.0**: User-based authentication

## 📝 Usage Examples

### Azure Deployment Examples

**Static Web App**:
```powershell
Deploy-Azure -AppName "portfolio-prod" -ResourceGroup "rg-portfolio" -SubscriptionId "abc123" -DeploymentType "static" -CustomDomain "johndoe.com" -Subdomain "portfolio"
```

**App Service**:
```powershell
Deploy-Azure -AppName "backend-api" -ResourceGroup "rg-api" -SubscriptionId "abc123" -DeploymentType "appservice" -CustomDomain "mycompany.com" -Subdomain "api"
```

**Auto-Detect**:
```powershell
Deploy-Azure -AppName "my-app" -ResourceGroup "rg-app" -SubscriptionId "abc123" -ProjectPath "C:\Projects\my-app"
```

### Vercel Deployment Examples
```powershell
Deploy-Vercel -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-nextjs-app" -Location "us-east-1" -VercelToken "ver_abc123" -CustomDomain "myapp.com"
```

### Netlify Deployment Examples
```powershell
Deploy-Netlify -AppName "my-jamstack-site" -ProjectPath "C:\Projects\my-jamstack-site" -Location "us-east-1" -NetlifyToken "abc123" -CustomDomain "myapp.com"
```

### AWS Deployment Examples
```powershell
Deploy-AWS -AppName "my-static-site" -ProjectPath "C:\Projects\my-static-site" -Location "us-east-1" -AwsRegion "us-east-1" -CustomDomain "myapp.com"
```

### Google Cloud Deployment Examples
```powershell
Deploy-GoogleCloud -AppName "my-app" -ProjectPath "C:\Projects\my-app" -Location "us-central1" -GcpProject "my-project" -DeploymentType "cloudrun" -CustomDomain "myapp.com"
```

## 🎛️ Interactive Menu System

### Website Deployment Menu
Access through the HomeLab interactive menu:

```
=== Website Deployment ===
1. Auto-Detect and Deploy Website
2. Deploy Static Web App (Azure)
3. Deploy App Service (Azure)
4. Deploy to Vercel
5. Deploy to Netlify
6. Deploy to AWS
7. Deploy to Google Cloud
8. Configure Custom Domain
9. Add GitHub Workflows
10. Back to Main Menu
```

### Platform Selection
The system guides you through platform selection:

```
Step 1: Cloud Platform Selection
Choose your deployment platform:
1. Azure (Static Web Apps & App Service)
2. Vercel (Next.js, React, Vue optimized)
3. Netlify (JAMstack platform)
4. AWS (S3 + CloudFront)
5. Google Cloud (Cloud Run & App Engine)
6. Auto-detect (recommended)
```

## 🔄 GitHub Integration

### Automated Workflows
All platforms support GitHub Actions integration:

- **Azure**: OIDC federation for secure authentication
- **Vercel**: Automatic deployments from Git
- **Netlify**: Continuous deployment with build hooks
- **AWS**: CodePipeline integration
- **Google Cloud**: Cloud Build integration

### Repository Suggestions
AI-powered repository analysis provides intelligent suggestions based on:
- Project type and framework
- Recent activity and popularity
- Repository size and complexity
- Community engagement metrics

## 🌐 Custom Domain Configuration

### DNS Configuration by Platform

#### Azure DNS Configuration
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurestaticapps.net (Static Web Apps)
Value: {app-name}.azurewebsites.net (App Service)
```

#### Vercel DNS Configuration
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.vercel.app
```

#### Netlify DNS Configuration
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.netlify.app
```

#### AWS DNS Configuration
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.s3-website-{region}.amazonaws.com
```

#### Google Cloud DNS Configuration
```
Type: CNAME
Name: {subdomain}
Value: {app-name}-{hash}.run.app (Cloud Run)
Value: {app-name}.appspot.com (App Engine)
```

## 🎯 Key Features

- ✅ **Multi-Platform Support** - Deploy to 5 major cloud platforms
- ✅ **Intelligent Auto-Detection** - Automatically chooses optimal deployment type
- ✅ **Progress Tracking** - Step-by-step deployment progress
- ✅ **AI Repository Suggestions** - Smart repository recommendations
- ✅ **Custom Domain Support** - Deploy to your own domain with subdomains
- ✅ **Multi-Environment Deployment** - Deploy to dev, staging, and prod
- ✅ **GitHub Integration** - Automated CI/CD workflows
- ✅ **SSL Certificate Automation** - Free SSL certificates for all platforms
- ✅ **Cost Optimization** - Choose the most cost-effective platform
- ✅ **Consistent Interface** - Unified experience across all platforms
- ✅ **First-Class Azure Support** - Comprehensive Azure resource management

## 🚀 Getting Started

1. **Choose Your Platform**: Select from Azure, Vercel, Netlify, AWS, or Google Cloud
2. **Prepare Your Project**: Ensure your project is ready for deployment
3. **Run Deployment**: Use the interactive menu or direct function calls
4. **Configure Domain**: Set up custom domains and DNS records
5. **Monitor & Optimize**: Track performance and costs

## 📚 Additional Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Vercel Documentation](https://vercel.com/docs)
- [Netlify Documentation](https://docs.netlify.com/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [HomeLab API Reference](./API-REFERENCE.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)