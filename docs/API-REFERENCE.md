# PowerShell Module API Reference

This document provides a comprehensive reference for all public functions in the HomeLab PowerShell modules.

## Table of Contents

- [HomeLab.Core](#homelabcore)
- [HomeLab.Azure](#homelabazure)
- [HomeLab.Security](#homelabsecurity)
- [HomeLab.Web](#homelabweb)
- [HomeLab.DNS](#homelabdns)
- [HomeLab.GitHub](#homelabgithub)
- [HomeLab.UI](#homelabui)
- [HomeLab.Monitoring](#homelabmonitoring)

## HomeLab.Core

### Configuration Management

#### Get-HomeLabConfiguration
**Synopsis**: Loads and validates the HomeLab configuration.

**Syntax**:
```powershell
Get-HomeLabConfiguration [[-Path] <String>] [<CommonParameters>]
```

**Parameters**:
- `Path` (Optional): Custom path to configuration file

**Returns**: Configuration object with validated settings

**Example**:
```powershell
$config = Get-HomeLabConfiguration
$customConfig = Get-HomeLabConfiguration -Path "C:\Custom\config.json"
```

#### Set-HomeLabConfiguration
**Synopsis**: Updates HomeLab configuration settings.

**Syntax**:
```powershell
Set-HomeLabConfiguration [[-Environment] <String>] [[-LogLevel] <String>] [[-AzureLocation] <String>] [<CommonParameters>]
```

**Parameters**:
- `Environment`: Target environment (dev, staging, prod)
- `LogLevel`: Logging level (Debug, Info, Warning, Error)
- `AzureLocation`: Default Azure region

**Example**:
```powershell
Set-HomeLabConfiguration -Environment "prod" -LogLevel "Info"
```

### Logging System

#### Write-HomeLabLog
**Synopsis**: Writes structured log messages.

**Syntax**:
```powershell
Write-HomeLabLog [-Message] <String> [[-Level] <String>] [[-Exception] <Exception>] [<CommonParameters>]
```

**Parameters**:
- `Message`: Log message text
- `Level`: Log level (Debug, Info, Warning, Error)
- `Exception`: Optional exception object

**Example**:
```powershell
Write-HomeLabLog -Message "Deployment started" -Level Info
Write-HomeLabLog -Message "Error occurred" -Level Error -Exception $_.Exception
```

### Utility Functions

#### Test-HomeLabPrerequisites
**Synopsis**: Validates required tools and permissions.

**Syntax**:
```powershell
Test-HomeLabPrerequisites [<CommonParameters>]
```

**Returns**: Object with validation results and missing items

**Example**:
```powershell
$prereqs = Test-HomeLabPrerequisites
if (-not $prereqs.IsValid) {
    Write-Host "Missing: $($prereqs.MissingItems -join ', ')"
}
```

## HomeLab.Azure

### Resource Deployment

#### Deploy-Infrastructure
**Synopsis**: Deploys core Azure infrastructure.

**Syntax**:
```powershell
Deploy-Infrastructure [[-ResourceGroup] <String>] [[-Location] <String>] [[-Environment] <String>] [-Monitor] [-BackgroundMonitor] [<CommonParameters>]
```

**Parameters**:
- `ResourceGroup`: Target resource group name
- `Location`: Azure region for deployment
- `Environment`: Environment type (dev, staging, prod)
- `Monitor`: Enable deployment monitoring
- `BackgroundMonitor`: Enable background monitoring

**Example**:
```powershell
Deploy-Infrastructure -ResourceGroup "rg-homelab-prod" -Location "eastus" -Environment "prod"
```

#### Deploy-VPNGateway
**Synopsis**: Deploys and configures VPN Gateway.

**Syntax**:
```powershell
Deploy-VPNGateway [[-ResourceGroup] <String>] [[-GatewayName] <String>] [[-VNetName] <String>] [<CommonParameters>]
```

**Parameters**:
- `ResourceGroup`: Resource group containing the VNet
- `GatewayName`: Name for the VPN Gateway
- `VNetName`: Virtual network name

**Example**:
```powershell
Deploy-VPNGateway -ResourceGroup "rg-homelab" -GatewayName "vpn-gateway" -VNetName "vnet-homelab"
```

### Resource Management

#### Get-AzureResourceStatus
**Synopsis**: Gets status of Azure resources.

**Syntax**:
```powershell
Get-AzureResourceStatus [[-ResourceGroup] <String>] [[-ResourceType] <String>] [<CommonParameters>]
```

**Parameters**:
- `ResourceGroup`: Filter by resource group
- `ResourceType`: Filter by resource type

**Returns**: Array of resource status objects

**Example**:
```powershell
$status = Get-AzureResourceStatus -ResourceGroup "rg-homelab"
$vpnStatus = Get-AzureResourceStatus -ResourceType "Microsoft.Network/virtualNetworkGateways"
```

## HomeLab.Security

### Certificate Management

#### New-VPNCertificate
**Synopsis**: Creates VPN certificates for authentication.

**Syntax**:
```powershell
New-VPNCertificate [[-CertificateName] <String>] [[-SubjectName] <String>] [[-ValidityPeriod] <Int32>] [<CommonParameters>]
```

**Parameters**:
- `CertificateName`: Name for the certificate
- `SubjectName`: Certificate subject name
- `ValidityPeriod`: Validity period in days

**Returns**: Certificate object with public key data

**Example**:
```powershell
$cert = New-VPNCertificate -CertificateName "HomeLabVPN" -SubjectName "CN=HomeLabVPN" -ValidityPeriod 365
```

#### Install-VPNCertificate
**Synopsis**: Installs VPN certificates to the certificate store.

**Syntax**:
```powershell
Install-VPNCertificate [-Certificate] <X509Certificate2> [[-StoreName] <String>] [[-StoreLocation] <String>] [<CommonParameters>]
```

**Parameters**:
- `Certificate`: Certificate object to install
- `StoreName`: Certificate store name (default: My)
- `StoreLocation`: Store location (CurrentUser, LocalMachine)

**Example**:
```powershell
Install-VPNCertificate -Certificate $cert -StoreName "My" -StoreLocation "CurrentUser"
```

### VPN Management

#### Connect-VPN
**Synopsis**: Connects to the VPN using configured profile.

**Syntax**:
```powershell
Connect-VPN [[-ProfileName] <String>] [<CommonParameters>]
```

**Parameters**:
- `ProfileName`: VPN profile name (default: HomeLab)

**Example**:
```powershell
Connect-VPN -ProfileName "HomeLab"
```

#### Disconnect-VPN
**Synopsis**: Disconnects from the VPN.

**Syntax**:
```powershell
Disconnect-VPN [[-ProfileName] <String>] [<CommonParameters>]
```

**Example**:
```powershell
Disconnect-VPN -ProfileName "HomeLab"
```

## HomeLab.Web

### Multi-Platform Website Deployment

#### Deploy-Website
**Synopsis**: Main deployment orchestrator that routes to platform-specific deployment functions.

**Syntax**:
```powershell
Deploy-Website [[-DeploymentType] <String>] [[-Platform] <String>] [[-AppName] <String>] [[-ResourceGroup] <String>] [[-Location] <String>] [[-CustomDomain] <String>] [[-Subdomain] <String>] [[-Environment] <String>] [[-ProjectPath] <String>] [[-RepoUrl] <String>] [[-Branch] <String>] [[-GitHubToken] <SecureString>] [[-SubscriptionId] <String>] [[-VercelToken] <String>] [[-NetlifyToken] <String>] [[-AwsRegion] <String>] [[-GcpProject] <String>] [<CommonParameters>]
```

**Parameters**:
- `DeploymentType`: Deployment type (static, appservice, auto, vercel, netlify, aws, gcp)
- `Platform`: Target platform (azure, vercel, netlify, aws, gcp)
- `AppName`: Application name
- `ResourceGroup`: Target resource group (Azure only)
- `Location`: Deployment region
- `CustomDomain`: Custom domain name
- `Subdomain`: Subdomain prefix
- `Environment`: Environment (dev, staging, prod)
- `ProjectPath`: Path to project directory
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy
- `GitHubToken`: GitHub personal access token
- `SubscriptionId`: Azure subscription ID
- `VercelToken`: Vercel API token
- `NetlifyToken`: Netlify API token
- `AwsRegion`: AWS region
- `GcpProject`: Google Cloud project ID

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-Website -DeploymentType "vercel" -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-app" -Location "us-east-1"
```

#### Deploy-Azure
**Synopsis**: Dedicated Azure deployment function for Static Web Apps and App Service.

**Syntax**:
```powershell
Deploy-Azure [-AppName] <String> [-ResourceGroup] <String> [-SubscriptionId] <String> [[-Location] <String>] [[-DeploymentType] <String>] [[-CustomDomain] <String>] [[-Subdomain] <String>] [[-GitHubToken] <SecureString>] [[-RepoUrl] <String>] [[-Branch] <String>] [[-ProjectPath] <String>] [<CommonParameters>]
```

**Parameters**:
- `AppName`: Application name for Azure resources
- `ResourceGroup`: Azure Resource Group name
- `SubscriptionId`: Azure subscription ID
- `Location`: Azure region (default: westeurope)
- `DeploymentType`: Type of deployment (static, appservice, auto)
- `CustomDomain`: Custom domain for the application
- `Subdomain`: Subdomain for the application
- `GitHubToken`: GitHub personal access token
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy (default: main)
- `ProjectPath`: Path to project directory

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-Azure -AppName "my-app" -ResourceGroup "my-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -DeploymentType "auto" -ProjectPath "C:\Projects\my-app"
```

#### Deploy-Vercel
**Synopsis**: Deploys websites to Vercel platform with framework optimization.

**Syntax**:
```powershell
Deploy-Vercel [-AppName] <String> [-ProjectPath] <String> [[-Location] <String>] [[-VercelToken] <String>] [[-CustomDomain] <String>] [[-RepoUrl] <String>] [[-Branch] <String>] [<CommonParameters>]
```

**Parameters**:
- `AppName`: Application name for Vercel
- `ProjectPath`: Path to project directory
- `Location`: Vercel region (default: us-east-1)
- `VercelToken`: Vercel API token
- `CustomDomain`: Custom domain for the application
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy (default: main)

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-Vercel -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -VercelToken "ver_abc123"
```

#### Deploy-Netlify
**Synopsis**: Deploys websites to Netlify platform optimized for JAMstack.

**Syntax**:
```powershell
Deploy-Netlify [-AppName] <String> [-ProjectPath] <String> [[-Location] <String>] [[-NetlifyToken] <String>] [[-CustomDomain] <String>] [[-RepoUrl] <String>] [[-Branch] <String>] [<CommonParameters>]
```

**Parameters**:
- `AppName`: Application name for Netlify
- `ProjectPath`: Path to project directory
- `Location`: Netlify region (default: us-east-1)
- `NetlifyToken`: Netlify API token
- `CustomDomain`: Custom domain for the application
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy (default: main)

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-Netlify -AppName "my-jamstack-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -NetlifyToken "abc123"
```

#### Deploy-AWS
**Synopsis**: Deploys websites to AWS using S3 and CloudFront.

**Syntax**:
```powershell
Deploy-AWS [-AppName] <String> [-ProjectPath] <String> [[-Location] <String>] [[-AwsRegion] <String>] [[-CustomDomain] <String>] [[-RepoUrl] <String>] [[-Branch] <String>] [<CommonParameters>]
```

**Parameters**:
- `AppName`: Application name for AWS
- `ProjectPath`: Path to project directory
- `Location`: AWS region (default: us-east-1)
- `AwsRegion`: AWS region for deployment
- `CustomDomain`: Custom domain for the application
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy (default: main)

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-AWS -AppName "my-static-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1" -AwsRegion "us-east-1"
```

#### Deploy-GoogleCloud
**Synopsis**: Deploys websites to Google Cloud using Cloud Run or App Engine.

**Syntax**:
```powershell
Deploy-GoogleCloud [-AppName] <String> [-ProjectPath] <String> [[-Location] <String>] [[-GcpProject] <String>] [[-CustomDomain] <String>] [[-RepoUrl] <String>] [[-Branch] <String>] [[-DeploymentType] <String>] [<CommonParameters>]
```

**Parameters**:
- `AppName`: Application name for Google Cloud
- `ProjectPath`: Path to project directory
- `Location`: Google Cloud region (default: us-central1)
- `GcpProject`: Google Cloud project ID
- `CustomDomain`: Custom domain for the application
- `RepoUrl`: GitHub repository URL
- `Branch`: Git branch to deploy (default: main)
- `DeploymentType`: Deployment type (cloudrun, appengine)

**Returns**: Deployment information hashtable

**Example**:
```powershell
Deploy-GoogleCloud -AppName "my-app" -ProjectPath "C:\Projects\my-app" -Location "us-central1" -GcpProject "my-project" -DeploymentType "cloudrun"
```

#### Get-WebsiteStatus
**Synopsis**: Gets status of deployed websites.

**Syntax**:
```powershell
Get-WebsiteStatus [[-ResourceGroup] <String>] [[-AppName] <String>] [<CommonParameters>]
```

**Returns**: Website status and configuration information

**Example**:
```powershell
$status = Get-WebsiteStatus -ResourceGroup "rg-web" -AppName "myapp"
```

## HomeLab.DNS

### DNS Zone Management

#### New-DNSZone
**Synopsis**: Creates a new DNS zone in Azure DNS.

**Syntax**:
```powershell
New-DNSZone [-ZoneName] <String> [[-ResourceGroup] <String>] [<CommonParameters>]
```

**Parameters**:
- `ZoneName`: DNS zone name (e.g., example.com)
- `ResourceGroup`: Resource group for the DNS zone

**Example**:
```powershell
New-DNSZone -ZoneName "example.com" -ResourceGroup "rg-dns"
```

#### Add-DNSRecord
**Synopsis**: Adds DNS records to a zone.

**Syntax**:
```powershell
Add-DNSRecord [-ZoneName] <String> [-RecordName] <String> [-RecordType] <String> [-Value] <String> [[-TTL] <Int32>] [<CommonParameters>]
```

**Parameters**:
- `ZoneName`: DNS zone name
- `RecordName`: Record name (e.g., www, api)
- `RecordType`: Record type (A, CNAME, TXT, MX)
- `Value`: Record value
- `TTL`: Time to live in seconds

**Example**:
```powershell
Add-DNSRecord -ZoneName "example.com" -RecordName "www" -RecordType "CNAME" -Value "myapp.azurewebsites.net"
```

## HomeLab.GitHub

### Repository Deployment

#### Deploy-GitHubRepository
**Synopsis**: Deploys GitHub repositories to Azure.

**Syntax**:
```powershell
Deploy-GitHubRepository [[-Repository] <Object>] [[-Branch] <String>] [[-ResourceGroup] <String>] [[-DeploymentType] <String>] [-Force] [-Monitor] [<CommonParameters>]
```

**Parameters**:
- `Repository`: Repository object or URL
- `Branch`: Git branch to deploy
- `ResourceGroup`: Target resource group
- `DeploymentType`: Deployment type (Infrastructure, WebApp, StaticSite, ContainerApp)
- `Force`: Force deployment even if exists
- `Monitor`: Enable deployment monitoring

**Example**:
```powershell
Deploy-GitHubRepository -Repository "user/repo" -DeploymentType "StaticSite" -ResourceGroup "rg-web"
```

#### Clone-GitHubRepository
**Synopsis**: Clones a GitHub repository locally.

**Syntax**:
```powershell
Clone-GitHubRepository [[-Repository] <Object>] [[-Branch] <String>] [[-DestinationPath] <String>] [-Force] [<CommonParameters>]
```

**Parameters**:
- `Repository`: Repository to clone
- `Branch`: Specific branch to clone
- `DestinationPath`: Local destination path
- `Force`: Overwrite existing directory

**Example**:
```powershell
$path = Clone-GitHubRepository -Repository "user/repo" -Branch "main"
```

## HomeLab.UI

### Menu System

#### Show-HomeLabMenu
**Synopsis**: Displays the main HomeLab interactive menu.

**Syntax**:
```powershell
Show-HomeLabMenu [<CommonParameters>]
```

**Example**:
```powershell
Show-HomeLabMenu
```

#### Start-HomeLab
**Synopsis**: Starts the HomeLab interactive system.

**Syntax**:
```powershell
Start-HomeLab [<CommonParameters>]
```

**Example**:
```powershell
Start-HomeLab
```

## HomeLab.Monitoring

### Health Checks

#### Test-HomeLabHealth
**Synopsis**: Performs comprehensive health checks.

**Syntax**:
```powershell
Test-HomeLabHealth [[-ResourceGroup] <String>] [-IncludePerformance] [<CommonParameters>]
```

**Parameters**:
- `ResourceGroup`: Scope health check to specific resource group
- `IncludePerformance`: Include performance metrics

**Returns**: Health check results object

**Example**:
```powershell
$health = Test-HomeLabHealth -ResourceGroup "rg-homelab" -IncludePerformance
```

### Cost Monitoring

#### Get-AzureCosts
**Synopsis**: Retrieves Azure cost information.

**Syntax**:
```powershell
Get-AzureCosts [[-SubscriptionId] <String>] [[-ResourceGroup] <String>] [[-TimeFrame] <String>] [<CommonParameters>]
```

**Parameters**:
- `SubscriptionId`: Azure subscription ID
- `ResourceGroup`: Filter by resource group
- `TimeFrame`: Time period (ThisMonth, LastMonth, Custom)

**Returns**: Cost analysis data

**Example**:
```powershell
$costs = Get-AzureCosts -ResourceGroup "rg-homelab" -TimeFrame "ThisMonth"
```

## Common Parameters

All functions support these common PowerShell parameters:

- `-Verbose`: Enable verbose output
- `-Debug`: Enable debug output
- `-ErrorAction`: Error action preference
- `-WarningAction`: Warning action preference
- `-InformationAction`: Information action preference
- `-ErrorVariable`: Error variable name
- `-WarningVariable`: Warning variable name
- `-InformationVariable`: Information variable name
- `-OutVariable`: Output variable name
- `-OutBuffer`: Output buffer size

## Error Handling

All functions follow consistent error handling patterns:

### Standard Error Types
- **ConfigurationError**: Configuration-related issues
- **AuthenticationError**: Azure authentication failures
- **ResourceNotFound**: Azure resources not found
- **DeploymentError**: Deployment failures
- **ValidationError**: Input validation failures

### Error Objects
Error objects include:
- `Message`: Human-readable error message
- `Category`: Error category
- `TargetObject`: Object that caused the error
- `Exception`: Underlying exception (if any)

### Example Error Handling
```powershell
try {
    Deploy-Website -DeploymentType "invalid"
}
catch [ValidationError] {
    Write-Host "Invalid deployment type specified" -ForegroundColor Red
}
catch {
    Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
}
```

## Return Objects

### Standard Return Patterns

#### Deployment Results
```powershell
@{
    Status = "Success|Failed|InProgress"
    ResourceGroup = "resource-group-name"
    Resources = @("resource1", "resource2")
    Url = "https://deployed-app.com"
    StartTime = [DateTime]
    Duration = [TimeSpan]
    Error = "error-message-if-failed"
}
```

#### Status Objects
```powershell
@{
    Name = "resource-name"
    Type = "resource-type"
    Status = "Running|Stopped|Failed"
    Location = "azure-region"
    Properties = @{ ... }
}
```

#### Health Check Results
```powershell
@{
    OverallHealth = "Healthy|Warning|Critical"
    Checks = @(
        @{
            Name = "check-name"
            Status = "Pass|Warning|Fail"
            Message = "check-result-message"
            Details = @{ ... }
        }
    )
    Timestamp = [DateTime]
}
```

## Version Information

To get version information for the HomeLab modules:

```powershell
Get-Module HomeLab* | Select-Object Name, Version
Get-HomeLabVersion  # From HomeLab.Core
```

## Related Documentation

- [Development Guide](DEVELOPMENT.md) - Development setup and guidelines
- [Testing Guide](TESTING.md) - Testing framework and procedures
- [GitHub Integration](GITHUB-INTEGRATION.md) - GitHub Actions and workflows
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions

## Support

For API-related questions:
1. Check function help: `Get-Help <FunctionName> -Full`
2. Review examples in this documentation
3. Check the [Development Guide](DEVELOPMENT.md)
4. Open an issue in the GitHub repository