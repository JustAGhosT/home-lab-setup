# HomeLab Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1. Clone and Navigate
```bash
git clone https://github.com/JustAGhosT/home-lab-setup.git
cd home-lab-setup
```

### 2. Choose Your Entry Point

#### 🎯 **Quick Website Deployment** (Most Popular)
```powershell
.\Deploy-Website.ps1
```
- Interactive GUI form with GitHub integration
- Auto-populates Azure subscription information
- Supports both local projects and GitHub repositories
- Validates all inputs before deployment

#### 🏠 **Full Interactive Menu**
```powershell
.\Start.ps1
```
- Complete HomeLab management interface
- VPN, DNS, monitoring, and more
- Perfect for comprehensive lab management

#### ⚡ **Command Line Deployment**
```powershell
# Static website example
.\Deploy-Website.ps1 -DeploymentType static -ResourceGroup "rg-portfolio" -AppName "portfolio-prod" -SubscriptionId "your-sub-id" -CustomDomain "example.com" -Subdomain "www"

# App service example  
.\Deploy-Website.ps1 -DeploymentType appservice -ResourceGroup "rg-api" -AppName "backend-api" -SubscriptionId "your-sub-id"

# Auto-detect project type
.\Deploy-Website.ps1 -DeploymentType auto -ResourceGroup "rg-myapp" -AppName "myapp" -SubscriptionId "your-sub-id" -ProjectPath "C:\Projects\MyWebApp"
```

### 3. Follow the Prompts
The system will:
- ✅ Check for required Azure PowerShell modules
- ✅ Verify your Azure authentication  
- ✅ Guide you through parameter collection
- ✅ Deploy your application to Azure
- ✅ Configure custom domains (if specified)
- ✅ Set up CI/CD workflows (optional)

## 🎛️ Input Methods

### GUI Form (Recommended)
- **GitHub Integration**: Automatically lists your repositories
- **Smart Defaults**: Pre-populates Azure subscription info
- **Validation**: Checks all inputs before deployment
- **Path Browser**: Easy project folder selection

### Command Line Prompts
- **Guided Questions**: Step-by-step parameter collection
- **Smart Defaults**: Uses current Azure context
- **Flexible Input**: Accept both GitHub repos and local paths

## 🌐 Deployment Types

| Type | Best For | Examples |
| ---- | -------- | -------- |
| **static** | Static sites, SPAs, JAMstack | React, Vue, Angular, Hugo, Jekyll |
| **appservice** | Dynamic web apps | Node.js/Express, Python/Django, .NET, PHP |
| **auto** | Let system decide | Any project - analyzes files to determine type |

## 📁 Project Sources

### Local Path
- Point to any local project directory
- System analyzes project structure
- Suitable for immediate deployment

### GitHub Repository  
- Select from your GitHub repositories
- Automatic CI/CD setup with GitHub Actions
- Perfect for ongoing development

## 🔗 Quick Links

- [Full Documentation](docs/WEBSITE-DEPLOYMENT.md)
- [Prerequisites](docs/PREREQUISITES.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [GitHub Integration](docs/GITHUB-INTEGRATION.md)

## 🆘 Need Help?

```powershell
# Show detailed help for any script
Get-Help .\Deploy-Website.ps1 -Detailed
Get-Help .\Start.ps1 -Detailed

# Access help from Start menu
.\Start.ps1 -Help
```

## 🎯 Common Examples

### Deploy a React App
```powershell
.\Deploy-Website.ps1 -DeploymentType static -ResourceGroup "rg-react-app" -AppName "my-react-app" -SubscriptionId "your-sub-id" -ProjectPath "C:\Projects\my-react-app"
```

### Deploy a Node.js API
```powershell
.\Deploy-Website.ps1 -DeploymentType appservice -ResourceGroup "rg-node-api" -AppName "my-node-api" -SubscriptionId "your-sub-id" -ProjectPath "C:\Projects\my-api"
```

### Deploy from GitHub with Custom Domain
```powershell
.\Deploy-Website.ps1 -DeploymentType auto -ResourceGroup "rg-portfolio" -AppName "portfolio" -SubscriptionId "your-sub-id" -RepoUrl "https://github.com/username/portfolio.git" -CustomDomain "example.com" -Subdomain "www"
```

---

**💡 Pro Tip**: Start with `.\Deploy-Website.ps1` for the best experience. The GUI form will help you get familiar with all the options!