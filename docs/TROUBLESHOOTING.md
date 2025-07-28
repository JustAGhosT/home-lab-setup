# Troubleshooting Guide

This guide provides solutions to common issues encountered when using the HomeLab system.

## Quick Diagnostics

### Health Check
```powershell
# Run comprehensive health check
Test-HomeLabHealth -IncludePerformance

# Check specific resource group
Test-HomeLabHealth -ResourceGroup "rg-homelab"
```

### Configuration Validation
```powershell
# Validate configuration
Test-HomeLabConfiguration

# Check prerequisites
Test-HomeLabPrerequisites
```

## Common Issues

### Installation and Setup

#### PowerShell Module Import Errors
**Symptoms**: Module not found or import failures
```
Import-Module : The specified module 'HomeLab' was not loaded
```

**Solutions**:
```powershell
# Clear module cache and reimport
Remove-Module HomeLab -Force -ErrorAction SilentlyContinue
Import-Module .\HomeLab.psd1 -Force

# Check module path
$env:PSModulePath -split ';'

# Install missing dependencies
Install-Module -Name Az -AllowClobber -Force
Install-Module -Name Pester -MinimumVersion 5.0 -Force
```

#### Prerequisites Check Failures
**Symptoms**: Missing tools or insufficient permissions
```
Warning: Missing required tools or permissions
```

**Solutions**:
```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install PowerShell 7+
winget install Microsoft.PowerShell

# Update Azure PowerShell
Update-Module -Name Az -Force

# Check permissions
Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id
```

### Azure Authentication

#### Authentication Failures
**Symptoms**: Unable to authenticate to Azure
```
Connect-AzAccount : AADSTS50020: User account is disabled
```

**Solutions**:
```powershell
# Clear Azure context and re-authenticate
Clear-AzContext -Force
Connect-AzAccount

# Use specific tenant
Connect-AzAccount -TenantId "your-tenant-id"

# Use service principal
$credential = Get-Credential
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId "tenant-id"

# Check current context
Get-AzContext
```

#### Subscription Access Issues
**Symptoms**: Cannot access subscription or resources
```
Get-AzResourceGroup : The subscription 'xxx' could not be found
```

**Solutions**:
```powershell
# List available subscriptions
Get-AzSubscription

# Set correct subscription
Set-AzContext -SubscriptionId "your-subscription-id"

# Verify permissions
Get-AzRoleAssignment | Where-Object { $_.SignInName -eq (Get-AzContext).Account.Id }
```

### VPN Gateway Issues

#### VPN Gateway Deployment Timeouts
**Symptoms**: Deployment takes longer than expected or times out
```
Error: The operation was canceled
```

**Solutions**:
```powershell
# Check deployment status
Get-AzResourceGroupDeployment -ResourceGroupName "rg-homelab"

# Monitor specific deployment
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName "rg-homelab" -Name "vpn-deployment"
$deployment.ProvisioningState

# Increase timeout (VPN Gateway takes 30-45 minutes)
# Wait and check status periodically
do {
    Start-Sleep -Seconds 300  # Wait 5 minutes
    $gateway = Get-AzVirtualNetworkGateway -ResourceGroupName "rg-homelab" -Name "vpn-gateway"
    Write-Host "Gateway Status: $($gateway.ProvisioningState)"
} while ($gateway.ProvisioningState -eq "Updating")
```

#### VPN Connection Issues
**Symptoms**: Cannot connect to VPN or connection drops
```
Error: The network connection between your computer and the VPN server could not be established
```

**Solutions**:
```powershell
# Verify certificate installation
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*HomeLab*" }
Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object { $_.Subject -like "*HomeLab*" }

# Check VPN Gateway status
$gateway = Get-AzVirtualNetworkGateway -ResourceGroupName "rg-homelab" -Name "vpn-gateway"
$gateway.ProvisioningState

# Verify Point-to-Site configuration
$p2sConfig = Get-AzVirtualNetworkGateway -ResourceGroupName "rg-homelab" -Name "vpn-gateway"
$p2sConfig.VpnClientConfiguration

# Download new VPN client configuration
$profile = New-AzVpnClientConfiguration -ResourceGroupName "rg-homelab" -Name "vpn-gateway"
```

#### Certificate Issues
**Symptoms**: Certificate errors or authentication failures
```
Error: The certificate is not valid for this use
```

**Solutions**:
```powershell
# Recreate certificates
$rootCert = New-VPNCertificate -CertificateName "HomeLabVPNRoot" -SubjectName "CN=HomeLabVPNRoot"
$clientCert = New-VPNCertificate -CertificateName "HomeLabVPNClient" -SubjectName "CN=HomeLabVPNClient"

# Install certificates
Install-VPNCertificate -Certificate $rootCert -StoreName "Root" -StoreLocation "CurrentUser"
Install-VPNCertificate -Certificate $clientCert -StoreName "My" -StoreLocation "CurrentUser"

# Add root certificate to VPN Gateway
Add-AzVpnClientRootCertificate -VpnClientRootCertificateName "HomeLabVPNRoot" -ResourceGroupName "rg-homelab" -VirtualNetworkGatewayName "vpn-gateway" -PublicCertData $rootCert.PublicKey
```

### Website Deployment Issues

#### App Service Deployment Failures
**Symptoms**: Website deployment fails or returns errors
```
Error: Web app deployment failed with status code 500
```

**Solutions**:
```powershell
# Check App Service status
Get-AzWebApp -ResourceGroupName "rg-web" -Name "myapp"

# View deployment logs
Get-AzWebAppDeploymentLog -ResourceGroupName "rg-web" -Name "myapp"

# Restart App Service
Restart-AzWebApp -ResourceGroupName "rg-web" -Name "myapp"

# Check App Service Plan
Get-AzAppServicePlan -ResourceGroupName "rg-web"

# Scale up if needed
Set-AzAppServicePlan -ResourceGroupName "rg-web" -Name "plan-name" -Tier "Basic" -NumberofWorkers 1 -WorkerSize "Small"
```

#### Custom Domain Configuration Issues
**Symptoms**: Custom domain not working or SSL certificate errors
```
Error: Domain verification failed
```

**Solutions**:
```powershell
# Verify DNS records
nslookup myapp.example.com
nslookup asuid.myapp.example.com

# Check domain verification status
Get-AzWebAppDomainVerificationId -ResourceGroupName "rg-web" -Name "myapp"

# Add custom domain
Set-AzWebAppCustomDomain -ResourceGroupName "rg-web" -Name "myapp" -HostName "myapp.example.com"

# Enable SSL
New-AzWebAppSSLBinding -ResourceGroupName "rg-web" -WebAppName "myapp" -Name "myapp.example.com" -SslState SniEnabled
```

#### Static Web App Issues
**Symptoms**: Static Web App deployment or routing issues
```
Error: Static Web App build failed
```

**Solutions**:
```powershell
# Check Static Web App status
Get-AzStaticWebApp -ResourceGroupName "rg-web" -Name "mystaticapp"

# View build logs in Azure Portal
# Navigate to Static Web App > Functions > Monitor

# Check configuration file
# Ensure staticwebapp.config.json is properly configured

# Redeploy
# Push changes to connected GitHub repository or redeploy manually
```

### DNS Management Issues

#### DNS Zone Configuration Problems
**Symptoms**: DNS records not resolving or propagation issues
```
Error: DNS zone not found or inaccessible
```

**Solutions**:
```powershell
# Verify DNS zone exists
Get-AzDnsZone -ResourceGroupName "rg-dns" -Name "example.com"

# Check name servers
$zone = Get-AzDnsZone -ResourceGroupName "rg-dns" -Name "example.com"
$zone.NameServers

# Verify DNS records
Get-AzDnsRecordSet -ResourceGroupName "rg-dns" -ZoneName "example.com"

# Test DNS resolution
nslookup example.com
nslookup www.example.com

# Check DNS propagation (may take up to 48 hours)
# Use online tools like whatsmydns.net
```

#### DNS Record Management Issues
**Symptoms**: Cannot add, update, or delete DNS records
```
Error: The record set 'www' of type 'A' does not exist
```

**Solutions**:
```powershell
# List all record sets
Get-AzDnsRecordSet -ResourceGroupName "rg-dns" -ZoneName "example.com"

# Create missing record set
New-AzDnsRecordSet -ResourceGroupName "rg-dns" -ZoneName "example.com" -Name "www" -RecordType "A" -Ttl 3600

# Add record to existing set
$recordSet = Get-AzDnsRecordSet -ResourceGroupName "rg-dns" -ZoneName "example.com" -Name "www" -RecordType "A"
Add-AzDnsRecordConfig -RecordSet $recordSet -Ipv4Address "1.2.3.4"
Set-AzDnsRecordSet -RecordSet $recordSet

# Remove record
Remove-AzDnsRecordSet -ResourceGroupName "rg-dns" -ZoneName "example.com" -Name "www" -RecordType "A"
```

### GitHub Integration Issues

#### GitHub Actions Workflow Failures
**Symptoms**: Workflows fail or don't trigger
```
Error: The workflow is not valid. Authentication failed
```

**Solutions**:
```powershell
# Verify GitHub secrets are set correctly
# Check in repository Settings > Secrets and variables > Actions

# Required secrets for OIDC:
# AZURE_CLIENT_ID
# AZURE_TENANT_ID  
# AZURE_SUBSCRIPTION_ID
# GITHUB_TOKEN

# Test Azure authentication locally
az login --service-principal --username $env:AZURE_CLIENT_ID --tenant $env:AZURE_TENANT_ID

# Check federated credential configuration
az ad app federated-credential list --id $env:AZURE_CLIENT_ID

# Verify workflow file syntax
# Use GitHub's workflow validator or yamllint
```

#### Repository Deployment Issues
**Symptoms**: Repository deployment fails or times out
```
Error: Failed to clone repository or deployment timeout
```

**Solutions**:
```powershell
# Test repository access
$repo = Clone-GitHubRepository -Repository "user/repo" -Branch "main"

# Check deployment logs
Deploy-GitHubRepository -Repository "user/repo" -DeploymentType "auto" -Verbose

# Verify Azure resources exist
Get-AzResourceGroup -Name "rg-deployment"

# Check deployment type detection
$config = Get-RepositoryDeploymentConfig -Path $repo
$config.DeploymentType
```

### Testing Issues

#### Test Execution Failures
**Symptoms**: Tests fail to run or produce unexpected results
```
Error: Pester module not found or test failures
```

**Solutions**:
```powershell
# Install/update Pester
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# Clear module cache
Get-Module Pester | Remove-Module -Force
Import-Module Pester -MinimumVersion 5.0

# Run specific test type
.\Run-HomeLab-Tests.ps1 -TestType Unit -Verbose

# Check test configuration
$config = New-PesterConfiguration
$config.Run.Path = ".\tests\unit"
$config.Output.Verbosity = "Detailed"

# Run with coverage
.\Run-HomeLab-Tests.ps1 -Coverage -GenerateReport
```

#### Test Report Generation Issues
**Symptoms**: HTML reports not generated or PScribo errors
```
Error: PScribo module installation failed
```

**Solutions**:
```powershell
# Install PScribo manually
Install-Module -Name PScribo -Force -SkipPublisherCheck

# Use fallback HTML generation
# The test runner automatically falls back to simple HTML if PScribo fails

# Check report output
Test-Path ".\tests\TestReport.html"

# View test results
Get-Content ".\tests\TestResults.xml"
```

### Performance Issues

#### Slow Deployment Times
**Symptoms**: Deployments take longer than expected
```
Warning: Deployment is taking longer than usual
```

**Solutions**:
```powershell
# Check Azure service health
# Visit https://status.azure.com/

# Monitor deployment progress
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName "rg-homelab" -Name "deployment-name"
$deployment.ProvisioningState

# Use parallel deployment where possible
# Deploy independent resources in parallel

# Optimize resource configurations
# Use appropriate SKUs for your needs
```

#### High Azure Costs
**Symptoms**: Unexpected Azure charges
```
Warning: Azure costs are higher than expected
```

**Solutions**:
```powershell
# Check current costs
Get-AzureCosts -ResourceGroup "rg-homelab" -TimeFrame "ThisMonth"

# Identify expensive resources
Get-AzResource -ResourceGroupName "rg-homelab" | ForEach-Object {
    Get-AzResourceUsage -ResourceId $_.ResourceId
}

# Optimize costs
# - Disable NAT Gateway when not needed
# - Use appropriate VM sizes
# - Delete unused resources
# - Use Azure Cost Management recommendations
```

## Diagnostic Commands

### System Information
```powershell
# PowerShell version
$PSVersionTable

# Azure PowerShell version
Get-Module -Name Az -ListAvailable

# HomeLab version
Get-HomeLabVersion

# Current Azure context
Get-AzContext
```

### Network Diagnostics
```powershell
# Test connectivity
Test-NetConnection -ComputerName "gateway.azure.com" -Port 443

# Check DNS resolution
Resolve-DnsName "login.microsoftonline.com"

# VPN status
Get-VpnConnection -Name "HomeLab"
```

### Azure Resource Status
```powershell
# Resource group status
Get-AzResourceGroup -Name "rg-homelab"

# All resources in group
Get-AzResource -ResourceGroupName "rg-homelab"

# Specific resource status
Get-AzVirtualNetworkGateway -ResourceGroupName "rg-homelab" -Name "vpn-gateway"
```

## Log Analysis

### HomeLab Logs
```powershell
# View recent logs
Get-Content "$env:USERPROFILE\HomeLab\homelab.log" -Tail 50

# Filter by level
Get-Content "$env:USERPROFILE\HomeLab\homelab.log" | Where-Object { $_ -like "*ERROR*" }

# Enable debug logging
Set-HomeLabConfiguration -LogLevel "Debug"
```

### Azure Activity Logs
```powershell
# Recent activity
Get-AzLog -ResourceGroup "rg-homelab" -StartTime (Get-Date).AddHours(-1)

# Deployment logs
Get-AzLog -ResourceGroup "rg-homelab" -Status "Failed"
```

### Windows Event Logs
```powershell
# VPN events
Get-WinEvent -LogName "Application" | Where-Object { $_.ProviderName -like "*VPN*" }

# PowerShell errors
Get-WinEvent -LogName "Windows PowerShell" | Where-Object { $_.LevelDisplayName -eq "Error" }
```

## Getting Help

### Built-in Help
```powershell
# Function help
Get-Help Deploy-Website -Full
Get-Help Connect-VPN -Examples

# Module help
Get-Help HomeLab
```

### Community Resources
- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share experiences
- Documentation: Comprehensive guides and references

### Professional Support
For enterprise or critical deployments:
- Microsoft Azure Support
- PowerShell Community Forums
- Azure Architecture Center

## Prevention Tips

### Regular Maintenance
```powershell
# Update modules regularly
Update-Module -Name Az
Update-Module -Name Pester

# Run health checks
Test-HomeLabHealth -IncludePerformance

# Monitor costs
Get-AzureCosts -TimeFrame "ThisMonth"
```

### Best Practices
- Always test in development environment first
- Keep backups of important configurations
- Monitor Azure service health
- Use version control for configuration changes
- Document custom modifications

### Security Considerations
- Regularly rotate certificates
- Review access permissions
- Monitor for unusual activity
- Keep software updated
- Use least-privilege principles

## Related Documentation

- [Development Guide](DEVELOPMENT.md) - Development environment setup
- [Testing Guide](TESTING.md) - Testing procedures and debugging
- [GitHub Integration](GITHUB-INTEGRATION.md) - CI/CD troubleshooting
- [API Reference](API-REFERENCE.md) - Function documentation
- [Security Checklist](SECURITY-CHECKLIST.md) - Security best practices