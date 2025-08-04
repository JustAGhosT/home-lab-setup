<#
.SYNOPSIS
    Main entry point for HomeLab environment
.DESCRIPTION
    This script provides a streamlined entry point for the HomeLab environment
    with options to start different components or access the full interactive menu.
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: June 5, 2024
.EXAMPLE
    # Start the full interactive HomeLab menu
    .\Start.ps1
.EXAMPLE
    # Quick website deployment
    .\Start.ps1 -WebsiteDeployment
.EXAMPLE
    # Start VPN management
    .\Start.ps1 -VPNManagement
.EXAMPLE
    # Quick help
    .\Start.ps1 -Help
#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(ParameterSetName = 'WebsiteDeployment')]
    [switch]$WebsiteDeployment,
    
    [Parameter(ParameterSetName = 'VPNManagement')]
    [switch]$VPNManagement,
    
    [Parameter(ParameterSetName = 'DNSManagement')]
    [switch]$DNSManagement,
    
    [Parameter(ParameterSetName = 'Monitoring')]
    [switch]$Monitoring,
    
    [Parameter(ParameterSetName = 'Help')]
    [switch]$Help
)

# Function to display the quick start menu
function Show-QuickStartMenu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                              HomeLab Quick Start                            ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║  Welcome to the Azure HomeLab Management Environment!                       ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║  Choose from the options below to get started:                              ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║  1. 🌐 Deploy Website         - Deploy websites to Azure                    ║" -ForegroundColor Green
    Write-Host "║  2. 🔐 VPN Management         - Manage VPN connections and certificates     ║" -ForegroundColor Yellow
    Write-Host "║  3. 🌍 DNS Management         - Manage DNS zones and records               ║" -ForegroundColor Blue
    Write-Host "║  4. 📊 Monitoring & Alerts    - Monitor resources and set up alerts        ║" -ForegroundColor Magenta
    Write-Host "║  5. 🏠 Full HomeLab Menu      - Access complete interactive menu           ║" -ForegroundColor White
    Write-Host "║  6. 📚 Documentation          - View guides and documentation              ║" -ForegroundColor Cyan
    Write-Host "║  7. ❌ Exit                   - Close the application                       ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host
}

# Function to show documentation options
function Show-DocumentationMenu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                              Documentation Center                           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host
    Write-Host "Available Documentation:" -ForegroundColor Yellow
    Write-Host
    Write-Host "  1. Prerequisites Guide      - System requirements and setup" -ForegroundColor White
    Write-Host "  2. Setup Guide              - Step-by-step deployment instructions" -ForegroundColor White
    Write-Host "  3. Website Deployment       - How to deploy websites to Azure" -ForegroundColor White
    Write-Host "  4. VPN Configuration        - VPN setup and management" -ForegroundColor White
    Write-Host "  5. DNS Management           - DNS zone and record management" -ForegroundColor White
    Write-Host "  6. GitHub Integration       - CI/CD and repository deployment" -ForegroundColor White
    Write-Host "  7. Troubleshooting          - Common issues and solutions" -ForegroundColor White
    Write-Host "  8. Architecture Diagrams    - System architecture and network diagrams" -ForegroundColor White
    Write-Host "  9. Back to Main Menu        - Return to quick start menu" -ForegroundColor Gray
    Write-Host
    
    $choice = Read-Host "Select a documentation topic (1-9)"
    
    switch ($choice) {
        "1" { 
            if (Test-Path "docs/PREREQUISITES.md") {
                Get-Content "docs/PREREQUISITES.md" | Out-Host -Paging
            }
            else {
                Write-Host "Prerequisites guide not found." -ForegroundColor Red
            }
        }
        "2" { 
            if (Test-Path "docs/SETUP.md") {
                Get-Content "docs/SETUP.md" | Out-Host -Paging
            }
            else {
                Write-Host "Setup guide not found." -ForegroundColor Red
            }
        }
        "3" { 
            if (Test-Path "docs/WEBSITE-DEPLOYMENT.md") {
                Get-Content "docs/WEBSITE-DEPLOYMENT.md" | Out-Host -Paging
            }
            else {
                Write-Host "Website deployment guide not found." -ForegroundColor Red
            }
        }
        "4" { 
            if (Test-Path "docs/networking/vpn-gateway.md") {
                Get-Content "docs/networking/vpn-gateway.md" | Out-Host -Paging
            }
            else {
                Write-Host "VPN configuration guide not found." -ForegroundColor Red
            }
        }
        "5" { 
            Write-Host "Opening DNS management documentation..." -ForegroundColor Yellow
            Write-Host "DNS management documentation is integrated into the main HomeLab menu." -ForegroundColor White
        }
        "6" { 
            if (Test-Path "docs/GITHUB-INTEGRATION.md") {
                Get-Content "docs/GITHUB-INTEGRATION.md" | Out-Host -Paging
            }
            else {
                Write-Host "GitHub integration guide not found." -ForegroundColor Red
            }
        }
        "7" { 
            if (Test-Path "docs/TROUBLESHOOTING.md") {
                Get-Content "docs/TROUBLESHOOTING.md" | Out-Host -Paging
            }
            else {
                Write-Host "Troubleshooting guide not found." -ForegroundColor Red
            }
        }
        "8" { 
            Write-Host "Opening architecture diagrams..." -ForegroundColor Yellow
            if (Test-Path "docs/diagrams") {
                Get-ChildItem "docs/diagrams" -Filter "*.md" | ForEach-Object {
                    Write-Host "  - $($_.BaseName)" -ForegroundColor Cyan
                }
                Write-Host
                $diagramChoice = Read-Host "Enter diagram name to view (or press Enter to return)"
                if ($diagramChoice) {
                    $diagramPath = "docs/diagrams/$diagramChoice.md"
                    if (Test-Path $diagramPath) {
                        Get-Content $diagramPath | Out-Host -Paging
                    }
                    else {
                        Write-Host "Diagram not found: $diagramPath" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "Diagrams directory not found." -ForegroundColor Red
            }
        }
        "9" { return }
        default { 
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep 2
            Show-DocumentationMenu
        }
    }
    
    Write-Host
    Read-Host "Press Enter to continue"
}

# Function to import HomeLab module
function Import-HomeLabModule {
    try {
        $moduleBasePath = Join-Path -Path $PSScriptRoot -ChildPath "HomeLab"
        $modulePath = Join-Path -Path $moduleBasePath -ChildPath "HomeLab.psd1"
        
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            return $true
        }
        else {
            Write-Host "HomeLab module not found at: $modulePath" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error importing HomeLab module: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    return
}

# Handle direct parameter switches
if ($WebsiteDeployment) {
    Write-Host "Starting Website Deployment..." -ForegroundColor Green
    & "$PSScriptRoot\Deploy-Website.ps1"
    return
}

if ($VPNManagement -or $DNSManagement -or $Monitoring) {
    Write-Host "Starting HomeLab environment for specialized management..." -ForegroundColor Green
    if (-not (Import-HomeLabModule)) {
        Write-Host "Failed to import HomeLab module. Please ensure the repository is correctly set up." -ForegroundColor Red
        return
    }
    Start-HomeLab
    return
}

# Main interactive loop
do {
    Show-QuickStartMenu
    $choice = Read-Host "Please select an option (1-7)"
    
    switch ($choice) {
        "1" {
            Write-Host "Starting Website Deployment..." -ForegroundColor Green
            
            # Let's take the direct approach here
            Clear-Host
            Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║              WEBSITE DEPLOYMENT WIZARD                 ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            
            do {
                Write-Host "Please select website type:" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  1. Static Website (HTML, SPA, JAMstack apps)" -ForegroundColor White
                Write-Host "  2. App Service (Node.js, Python, .NET, PHP)" -ForegroundColor White 
                Write-Host "  3. Auto-Detect (Analyze and choose best option)" -ForegroundColor White
                Write-Host "  4. Return to Main Menu" -ForegroundColor Gray
                Write-Host ""
                
                $choice = Read-Host "Select option (1-4)"
                
                switch ($choice) {
                    "1" {
                        # Static website
                        Clear-Host
                        Write-Host "=== STATIC WEBSITE DEPLOYMENT ===" -ForegroundColor Cyan
                        Write-Host "Perfect for: HTML, React, Vue, Angular, etc." -ForegroundColor Yellow
                        Write-Host ""
                        
                        $resourceGroup = Read-Host "Resource Group name (e.g., rg-mywebsite)"
                        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                            Write-Host "Resource Group name is required" -ForegroundColor Red
                            break
                        }
                        
                        $appName = Read-Host "App Name (e.g., mywebsite-prod)"
                        if ([string]::IsNullOrWhiteSpace($appName)) {
                            Write-Host "App Name is required" -ForegroundColor Red
                            break
                        }
                        
                        # Get Azure subscription
                        try {
                            $context = Get-AzContext -ErrorAction Stop
                            if ($context) {
                                $subscriptions = Get-AzSubscription -ErrorAction Stop
                                
                                if ($subscriptions.Count -eq 1) {
                                    $subscriptionId = $subscriptions[0].Id
                                    Write-Host "Using subscription: $($subscriptions[0].Name) ($subscriptionId)" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Available subscriptions:" -ForegroundColor Yellow
                                    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                                        Write-Host "  $($i+1). $($subscriptions[$i].Name) ($($subscriptions[$i].Id))" -ForegroundColor White
                                    }
                                    
                                    $subChoice = Read-Host "Select subscription number (1-$($subscriptions.Count))"
                                    $subIndex = [int]$subChoice - 1
                                    
                                    if ($subIndex -ge 0 -and $subIndex -lt $subscriptions.Count) {
                                        $subscriptionId = $subscriptions[$subIndex].Id
                                    }
                                    else {
                                        $subscriptionId = Read-Host "Enter Subscription ID manually"
                                    }
                                }
                            }
                            else {
                                $subscriptionId = Read-Host "Enter Subscription ID"
                            }
                        }
                        catch {
                            Write-Host "Could not get Azure subscriptions: $($_.Exception.Message)" -ForegroundColor Yellow
                            $subscriptionId = Read-Host "Enter Subscription ID"
                        }
                        
                        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                            Write-Host "Subscription ID is required" -ForegroundColor Red
                            break
                        }
                        
                        # Ask for custom domain
                        $useDomain = Read-Host "Configure custom domain? (y/n)"
                        $customDomain = $null
                        $subdomain = $null
                        
                        if ($useDomain -eq "y") {
                            $customDomain = Read-Host "Enter domain (e.g., example.com)"
                            $subdomain = Read-Host "Enter subdomain (e.g., www)"
                        }
                        
                        # Confirm deployment
                        Write-Host ""
                        Write-Host "Ready to deploy:" -ForegroundColor Cyan
                        Write-Host "  Type: Static Website" -ForegroundColor White
                        Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
                        Write-Host "  App Name: $appName" -ForegroundColor White
                        Write-Host "  Subscription: $subscriptionId" -ForegroundColor White
                        
                        if ($customDomain) {
                            Write-Host "  Domain: $subdomain.$customDomain" -ForegroundColor White
                        }
                        
                        Write-Host ""
                        $confirm = Read-Host "Proceed with deployment? (y/n)"
                        
                        if ($confirm -eq "y") {
                            # Build params
                            $params = @{
                                DeploymentType = "static"
                                ResourceGroup  = $resourceGroup
                                AppName        = $appName
                                SubscriptionId = $subscriptionId
                            }
                            
                            if ($customDomain) {
                                $params.CustomDomain = $customDomain
                            }
                            
                            if ($subdomain) {
                                $params.Subdomain = $subdomain
                            }
                            
                            # Perform deployment
                            try {
                                Write-Host "Starting deployment..." -ForegroundColor Yellow
                                Deploy-Website @params
                                Write-Host "Deployment completed successfully!" -ForegroundColor Green
                            }
                            catch {
                                Write-Host "Deployment failed:" -ForegroundColor Red
                                Write-Host $_.Exception.Message -ForegroundColor Red
                                
                                if ($_.Exception.InnerException) {
                                    Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
                                }
                            }
                        }
                        else {
                            Write-Host "Deployment cancelled." -ForegroundColor Yellow
                        }
                    }
                    "2" {
                        # App Service
                        Clear-Host
                        Write-Host "=== APP SERVICE DEPLOYMENT ===" -ForegroundColor Cyan
                        Write-Host "Perfect for: Node.js, Python, .NET, PHP apps" -ForegroundColor Yellow
                        Write-Host ""
                        
                        $resourceGroup = Read-Host "Resource Group name (e.g., rg-myapi)"
                        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                            Write-Host "Resource Group name is required" -ForegroundColor Red
                            break
                        }
                        
                        $appName = Read-Host "App Name (e.g., myapi-prod)"
                        if ([string]::IsNullOrWhiteSpace($appName)) {
                            Write-Host "App Name is required" -ForegroundColor Red
                            break
                        }
                        
                        # Get Azure subscription
                        try {
                            $context = Get-AzContext -ErrorAction Stop
                            if ($context) {
                                $subscriptions = Get-AzSubscription -ErrorAction Stop
                                
                                if ($subscriptions.Count -eq 1) {
                                    $subscriptionId = $subscriptions[0].Id
                                    Write-Host "Using subscription: $($subscriptions[0].Name) ($subscriptionId)" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Available subscriptions:" -ForegroundColor Yellow
                                    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                                        Write-Host "  $($i+1). $($subscriptions[$i].Name) ($($subscriptions[$i].Id))" -ForegroundColor White
                                    }
                                    
                                    $subChoice = Read-Host "Select subscription number (1-$($subscriptions.Count))"
                                    $subIndex = [int]$subChoice - 1
                                    
                                    if ($subIndex -ge 0 -and $subIndex -lt $subscriptions.Count) {
                                        $subscriptionId = $subscriptions[$subIndex].Id
                                    }
                                    else {
                                        $subscriptionId = Read-Host "Enter Subscription ID manually"
                                    }
                                }
                            }
                            else {
                                $subscriptionId = Read-Host "Enter Subscription ID"
                            }
                        }
                        catch {
                            Write-Host "Could not get Azure subscriptions: $($_.Exception.Message)" -ForegroundColor Yellow
                            $subscriptionId = Read-Host "Enter Subscription ID"
                        }
                        
                        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                            Write-Host "Subscription ID is required" -ForegroundColor Red
                            break
                        }
                        
                        # Ask for custom domain
                        $useDomain = Read-Host "Configure custom domain? (y/n)"
                        $customDomain = $null
                        $subdomain = $null
                        
                        if ($useDomain -eq "y") {
                            $customDomain = Read-Host "Enter domain (e.g., example.com)"
                            $subdomain = Read-Host "Enter subdomain (e.g., api)"
                        }
                        
                        # Confirm deployment
                        Write-Host ""
                        Write-Host "Ready to deploy:" -ForegroundColor Cyan
                        Write-Host "  Type: App Service" -ForegroundColor White
                        Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
                        Write-Host "  App Name: $appName" -ForegroundColor White
                        Write-Host "  Subscription: $subscriptionId" -ForegroundColor White
                        
                        if ($customDomain) {
                            Write-Host "  Domain: $subdomain.$customDomain" -ForegroundColor White
                        }
                        
                        Write-Host ""
                        $confirm = Read-Host "Proceed with deployment? (y/n)"
                        
                        if ($confirm -eq "y") {
                            # Build params
                            $params = @{
                                DeploymentType = "appservice"
                                ResourceGroup  = $resourceGroup
                                AppName        = $appName
                                SubscriptionId = $subscriptionId
                            }
                            
                            if ($customDomain) {
                                $params.CustomDomain = $customDomain
                            }
                            
                            if ($subdomain) {
                                $params.Subdomain = $subdomain
                            }
                            
                            # Perform deployment
                            try {
                                Write-Host "Starting deployment..." -ForegroundColor Yellow
                                Deploy-Website @params
                                Write-Host "Deployment completed successfully!" -ForegroundColor Green
                            }
                            catch {
                                Write-Host "Deployment failed:" -ForegroundColor Red
                                Write-Host $_.Exception.Message -ForegroundColor Red
                                
                                if ($_.Exception.InnerException) {
                                    Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
                                }
                            }
                        }
                        else {
                            Write-Host "Deployment cancelled." -ForegroundColor Yellow
                        }
                    }
                    "3" {
                        # Auto-detect
                        Clear-Host
                        Write-Host "=== AUTO-DETECT AND DEPLOY WEBSITE ===" -ForegroundColor Cyan
                        Write-Host "Analyzes your project and chooses the best deployment type" -ForegroundColor Yellow
                        Write-Host ""
                        
                        # Get Resource Group with improved selection
                        try {
                            # Try to get existing resource groups
                            $existingRGs = Get-AzResourceGroup -ErrorAction Stop
                            
                            if ($existingRGs -and $existingRGs.Count -gt 0) {
                                Write-Host "Existing resource groups:" -ForegroundColor Yellow
                                for ($i = 0; $i -lt $existingRGs.Count; $i++) {
                                    Write-Host "  $($i+1). $($existingRGs[$i].ResourceGroupName) - $($existingRGs[$i].Location)" -ForegroundColor White
                                }
                                Write-Host "  N. Create New Resource Group" -ForegroundColor Green
                                
                                $rgChoice = Read-Host "Select resource group number or N for new"
                                
                                if ($rgChoice -eq "N" -or $rgChoice -eq "n") {
                                    $resourceGroup = Read-Host "Enter new Resource Group name (e.g., rg-myapp)"
                                }
                                else {
                                    $rgIndex = [int]$rgChoice - 1
                                    if ($rgIndex -ge 0 -and $rgIndex -lt $existingRGs.Count) {
                                        $resourceGroup = $existingRGs[$rgIndex].ResourceGroupName
                                    }
                                    else {
                                        $resourceGroup = Read-Host "Enter Resource Group name (e.g., rg-myapp)"
                                    }
                                }
                            }
                            else {
                                $resourceGroup = Read-Host "Enter Resource Group name (e.g., rg-myapp)"
                            }
                        }
                        catch {
                            Write-Host "Could not retrieve existing resource groups: $($_.Exception.Message)" -ForegroundColor Yellow
                            $resourceGroup = Read-Host "Enter Resource Group name (e.g., rg-myapp)"
                        }
                        
                        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                            Write-Host "Resource Group name is required" -ForegroundColor Red
                            break
                        }
                        
                        $appName = Read-Host "App Name (e.g., myapp-prod)"
                        if ([string]::IsNullOrWhiteSpace($appName)) {
                            Write-Host "App Name is required" -ForegroundColor Red
                            break
                        }
                        
                        # Get Azure subscription
                        try {
                            $context = Get-AzContext -ErrorAction Stop
                            if ($context) {
                                $subscriptions = Get-AzSubscription -ErrorAction Stop
                                
                                if ($subscriptions.Count -eq 1) {
                                    $subscriptionId = $subscriptions[0].Id
                                    Write-Host "Using subscription: $($subscriptions[0].Name) ($subscriptionId)" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Available subscriptions:" -ForegroundColor Yellow
                                    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                                        Write-Host "  $($i+1). $($subscriptions[$i].Name) ($($subscriptions[$i].Id))" -ForegroundColor White
                                    }
                                    
                                    $subChoice = Read-Host "Select subscription number (1-$($subscriptions.Count))"
                                    $subIndex = [int]$subChoice - 1
                                    
                                    if ($subIndex -ge 0 -and $subIndex -lt $subscriptions.Count) {
                                        $subscriptionId = $subscriptions[$subIndex].Id
                                    }
                                    else {
                                        $subscriptionId = Read-Host "Enter Subscription ID manually"
                                    }
                                }
                            }
                            else {
                                $subscriptionId = Read-Host "Enter Subscription ID"
                            }
                        }
                        catch {
                            Write-Host "Could not get Azure subscriptions: $($_.Exception.Message)" -ForegroundColor Yellow
                            $subscriptionId = Read-Host "Enter Subscription ID"
                        }
                        
                        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                            Write-Host "Subscription ID is required" -ForegroundColor Red
                            break
                        }
                        
                        # Determine project source with GitHub integration
                        Write-Host ""
                        Write-Host "Select project source:" -ForegroundColor Yellow
                        Write-Host "  1. Local Folder (from this computer)" -ForegroundColor White
                        Write-Host "  2. GitHub Repository" -ForegroundColor White
                        
                        $sourceChoice = Read-Host "Select source (1-2)"
                        $projectPath = $null
                        $repoUrl = $null
                        $branch = "main"
                        
                        if ($sourceChoice -eq "1") {
                            # Local folder
                            Write-Host ""
                            Write-Host "Please specify the project folder to analyze:" -ForegroundColor Yellow
                            $projectPath = Read-Host "Enter project path"
                            
                            if ([string]::IsNullOrWhiteSpace($projectPath) -or -not (Test-Path $projectPath)) {
                                Write-Host "Invalid project path" -ForegroundColor Red
                                break
                            }
                        }
                        elseif ($sourceChoice -eq "2") {
                            # GitHub repository
                            Write-Host ""
                            Write-Host "GitHub Repository Selection:" -ForegroundColor Yellow
                            # Enhanced GitHub Token and Repository Management
                            function Get-GitHubToken {
                                # Check multiple possible locations for GitHub token
                                $token = $env:GITHUB_TOKEN
                                
                                if (-not $token) {
                                    # Try to get from git credential manager or user input
                                    Write-Host "GitHub token not found in environment." -ForegroundColor Yellow
                                    Write-Host "A Personal Access Token is needed to fetch your repositories automatically." -ForegroundColor White
                                    Write-Host "You can create one at: https://github.com/settings/tokens" -ForegroundColor Cyan
                                    
                                    $getTokenChoice = Read-Host "Enter GitHub token now? (y/n)"
                                    if ($getTokenChoice -eq "y") {
                                        $newToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
                                        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newToken)
                                        try {
                                            $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                                            
                                            # Test the token before saving
                                            try {
                                                $testHeaders = @{
                                                    'Authorization' = "token $plainToken"
                                                    'Accept'        = 'application/vnd.github.v3+json'
                                                    'User-Agent'    = 'HomeLab-PowerShell'
                                                }
                                                
                                                $testResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $testHeaders -Method Get
                                                Write-Host "Token validated successfully! Hello, $($testResponse.login)!" -ForegroundColor Green
                                                
                                                # Save to environment variables (both process and user level)
                                                $env:GITHUB_TOKEN = $plainToken
                                                [Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $plainToken, "User")
                                                Write-Host "GitHub token saved to environment variables" -ForegroundColor Green
                                                
                                                return $plainToken
                                            }
                                            catch {
                                                Write-Host "Invalid GitHub token: $($_.Exception.Message)" -ForegroundColor Red
                                                return $null
                                            }
                                        }
                                        finally {
                                            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                                        }
                                    }
                                }
                                else {
                                    Write-Host "Using GitHub token from environment" -ForegroundColor Green
                                    return $token
                                }
                                
                                return $null
                            }
                            
                            function Get-GitHubRepositories {
                                param([string]$Token)
                                
                                if (-not $Token) {
                                    return $null
                                }
                                
                                try {
                                    $headers = @{
                                        'Authorization' = "token $Token"
                                        'Accept'        = 'application/vnd.github.v3+json'
                                        'User-Agent'    = 'HomeLab-PowerShell'
                                    }
                                    
                                    Write-Host "Fetching your GitHub repositories..." -ForegroundColor Yellow
                                    
                                    # Get both owned and organization repos
                                    $ownedRepos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?sort=updated&per_page=50&type=owner" -Headers $headers -Method Get
                                    $memberRepos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?sort=updated&per_page=50&type=member" -Headers $headers -Method Get
                                    
                                    $allRepos = @()
                                    if ($ownedRepos) { $allRepos += $ownedRepos }
                                    if ($memberRepos) { $allRepos += $memberRepos }
                                    
                                    # Sort by last updated
                                    $sortedRepos = $allRepos | Sort-Object updated_at -Descending
                                    
                                    return $sortedRepos
                                }
                                catch {
                                    Write-Host "Error fetching repositories: $($_.Exception.Message)" -ForegroundColor Red
                                    return $null
                                }
                            }
                            
                            function Get-AISuggestedRepositories {
                                param([array]$Repositories)
                                
                                if (-not $Repositories -or $Repositories.Count -eq 0) {
                                    return @()
                                }
                                
                                # AI-powered repository analysis and scoring
                                $scoredRepos = @()
                                
                                foreach ($repo in $Repositories) {
                                    $score = 0
                                    $reasons = @()
                                    
                                    # Score based on language (web technologies get higher scores)
                                    $language = if ($repo.language) { $repo.language.ToLower() } else { "unknown" }
                                    switch ($language) {
                                        { $_ -in @("typescript", "javascript", "html", "css", "vue", "react") } { 
                                            $score += 30
                                            $reasons += "Web technology ($language)"
                                        }
                                        { $_ -in @("python", "c#", "java", "go", "rust") } { 
                                            $score += 25
                                            $reasons += "Backend technology ($language)"
                                        }
                                        { $_ -in @("powershell", "shell", "dockerfile", "yaml", "json") } { 
                                            $score += 15
                                            $reasons += "Infrastructure/Config ($language)"
                                        }
                                        default { 
                                            $score += 10
                                            $reasons += "Other technology ($language)"
                                        }
                                    }
                                    
                                    # Score based on description keywords
                                    $description = if ($repo.description) { $repo.description.ToLower() } else { "" }
                                    $keywords = @("website", "web", "app", "application", "frontend", "backend", "api", "ui", "dashboard", "landing", "portfolio", "blog", "static", "react", "vue", "angular", "next", "nuxt")
                                    foreach ($keyword in $keywords) {
                                        if ($description -like "*$keyword*") {
                                            $score += 5
                                            $reasons += "Contains '$keyword' in description"
                                            break
                                        }
                                    }
                                    
                                    # Score based on repository name patterns
                                    $repoName = $repo.name.ToLower()
                                    $namePatterns = @("web", "app", "site", "frontend", "ui", "dashboard", "landing", "portfolio", "blog", "static", "react", "vue", "angular")
                                    foreach ($pattern in $namePatterns) {
                                        if ($repoName -like "*$pattern*") {
                                            $score += 8
                                            $reasons += "Name contains '$pattern'"
                                            break
                                        }
                                    }
                                    
                                    # Score based on recent activity (higher score for recently updated)
                                    $daysSinceUpdate = (Get-Date) - ([DateTime]$repo.updated_at)
                                    if ($daysSinceUpdate.Days -le 7) {
                                        $score += 15
                                        $reasons += "Recently updated (< 7 days)"
                                    }
                                    elseif ($daysSinceUpdate.Days -le 30) {
                                        $score += 10
                                        $reasons += "Recently updated (< 30 days)"
                                    }
                                    elseif ($daysSinceUpdate.Days -le 90) {
                                        $score += 5
                                        $reasons += "Recently updated (< 90 days)"
                                    }
                                    
                                    # Score based on repository size (smaller repos are often better for deployment)
                                    if ($repo.size -le 1000) {
                                        $score += 10
                                        $reasons += "Small repository size"
                                    }
                                    elseif ($repo.size -le 10000) {
                                        $score += 5
                                        $reasons += "Medium repository size"
                                    }
                                    
                                    # Score based on stars (popularity indicator)
                                    if ($repo.stargazers_count -gt 0) {
                                        $score += 3
                                        $reasons += "Has stars ($($repo.stargazers_count))"
                                    }
                                    
                                    # Score based on forks (community interest)
                                    if ($repo.forks_count -gt 0) {
                                        $score += 2
                                        $reasons += "Has forks ($($repo.forks_count))"
                                    }
                                    
                                    # Add to scored repositories
                                    $scoredRepos += [PSCustomObject]@{
                                        Repository = $repo
                                        Score      = $score
                                        Reasons    = $reasons
                                    }
                                }
                                
                                # Sort by score (highest first) and return top 5
                                return ($scoredRepos | Sort-Object Score -Descending | Select-Object -First 5)
                            }
                            
                            function Select-GitHubRepository {
                                param([array]$Repositories)
                                
                                if (-not $Repositories -or $Repositories.Count -eq 0) {
                                    return $null
                                }
                                
                                Write-Host ""
                                Write-Host "Found $($Repositories.Count) repositories:" -ForegroundColor Green
                                Write-Host ""
                                
                                # Get AI suggestions
                                $suggestedRepos = Get-AISuggestedRepositories -Repositories $Repositories
                                
                                if ($suggestedRepos.Count -gt 0) {
                                    Write-Host "🤖 AI Suggestions (Best for deployment):" -ForegroundColor Cyan
                                    Write-Host ""
                                    
                                    for ($i = 0; $i -lt $suggestedRepos.Count; $i++) {
                                        $suggested = $suggestedRepos[$i]
                                        $repo = $suggested.Repository
                                        $repoName = $repo.full_name
                                        $description = if ($repo.description) { $repo.description } else { "No description" }
                                        $language = if ($repo.language) { $repo.language } else { "Unknown" }
                                        $lastUpdated = ([DateTime]$repo.updated_at).ToString("yyyy-MM-dd")
                                        
                                        Write-Host "  🎯 $($i+1)." -ForegroundColor Green -NoNewline
                                        Write-Host " $repoName" -ForegroundColor Cyan -NoNewline
                                        Write-Host " ($language)" -ForegroundColor Yellow -NoNewline
                                        Write-Host " - Updated: $lastUpdated" -ForegroundColor Gray -NoNewline
                                        Write-Host " [Score: $($suggested.Score)]" -ForegroundColor Magenta
                                        Write-Host "     $description" -ForegroundColor DarkGray
                                        
                                        # Show top reasons for suggestion
                                        if ($suggested.Reasons.Count -gt 0) {
                                            $topReasons = $suggested.Reasons | Select-Object -First 2
                                            Write-Host "     💡 Reasons: $($topReasons -join ', ')" -ForegroundColor DarkCyan
                                        }
                                        Write-Host ""
                                    }
                                    
                                    Write-Host "📋 All repositories:" -ForegroundColor Yellow
                                    Write-Host ""
                                }
                                
                                # Show repositories in a nice format
                                for ($i = 0; $i -lt [Math]::Min($Repositories.Count, 20); $i++) {
                                    $repo = $Repositories[$i]
                                    $repoName = $repo.full_name
                                    $description = if ($repo.description) { $repo.description } else { "No description" }
                                    $language = if ($repo.language) { $repo.language } else { "Unknown" }
                                    $lastUpdated = ([DateTime]$repo.updated_at).ToString("yyyy-MM-dd")
                                    
                                    # Check if this repo is in AI suggestions
                                    $isSuggested = $suggestedRepos | Where-Object { $_.Repository.id -eq $repo.id }
                                    $prefix = if ($isSuggested) { "🎯 " } else { "  " }
                                    $numberColor = if ($isSuggested) { "Green" } else { "White" }
                                    
                                    Write-Host "$prefix$($i+1)." -ForegroundColor $numberColor -NoNewline
                                    Write-Host " $repoName" -ForegroundColor Cyan -NoNewline
                                    Write-Host " ($language)" -ForegroundColor Yellow -NoNewline
                                    Write-Host " - Updated: $lastUpdated" -ForegroundColor Gray
                                    Write-Host "     $description" -ForegroundColor DarkGray
                                }
                                
                                if ($Repositories.Count -gt 20) {
                                    Write-Host "     ... and $($Repositories.Count - 20) more repositories" -ForegroundColor DarkGray
                                }
                                
                                Write-Host ""
                                if ($suggestedRepos.Count -gt 0) {
                                    Write-Host "  🎯 Quick select AI suggestion (1-$($suggestedRepos.Count))" -ForegroundColor Green
                                }
                                Write-Host "  M. Enter repository URL manually" -ForegroundColor Green
                                Write-Host ""
                                
                                do {
                                    $prompt = "Select repository number (1-$([Math]::Min($Repositories.Count, 20)))"
                                    if ($suggestedRepos.Count -gt 0) {
                                        $prompt += ", AI suggestion (🎯1-$($suggestedRepos.Count))"
                                    }
                                    $prompt += ", or M for manual entry"
                                    
                                    $repoChoice = Read-Host $prompt
                                    
                                    if ($repoChoice -eq "M" -or $repoChoice -eq "m") {
                                        return @{ Manual = $true }
                                    }
                                    
                                    # Check if it's an AI suggestion selection
                                    if ($repoChoice -like "🎯*" -or ($repoChoice -match '^\d+$' -and [int]$repoChoice -le $suggestedRepos.Count)) {
                                        $suggestionIndex = if ($repoChoice -like "🎯*") {
                                            [int]($repoChoice -replace '🎯', '') - 1
                                        }
                                        else {
                                            [int]$repoChoice - 1
                                        }
                                        
                                        if ($suggestionIndex -ge 0 -and $suggestionIndex -lt $suggestedRepos.Count) {
                                            $selectedSuggestion = $suggestedRepos[$suggestionIndex]
                                            Write-Host "Selected AI suggestion: $($selectedSuggestion.Repository.full_name) [Score: $($selectedSuggestion.Score)]" -ForegroundColor Green
                                            return $selectedSuggestion.Repository
                                        }
                                    }
                                    
                                    try {
                                        $repoIndex = [int]$repoChoice - 1
                                        if ($repoIndex -ge 0 -and $repoIndex -lt [Math]::Min($Repositories.Count, 20)) {
                                            return $Repositories[$repoIndex]
                                        }
                                        else {
                                            Write-Host "Invalid selection. Please choose a number between 1 and $([Math]::Min($Repositories.Count, 20)) or M." -ForegroundColor Red
                                        }
                                    }
                                    catch {
                                        Write-Host "Invalid selection. Please choose a number between 1 and $([Math]::Min($Repositories.Count, 20)) or M." -ForegroundColor Red
                                    }
                                } while ($true)
                            }
                            
                            # Get GitHub token
                            $githubToken = Get-GitHubToken
                            
                            if ($githubToken) {
                                # Fetch repositories
                                $repositories = Get-GitHubRepositories -Token $githubToken
                                
                                if ($repositories -and $repositories.Count -gt 0) {
                                    # Let user select repository
                                    $selectedRepo = Select-GitHubRepository -Repositories $repositories
                                    
                                    if ($selectedRepo -and -not $selectedRepo.Manual) {
                                        $repoUrl = $selectedRepo.clone_url
                                        Write-Host "Selected repository: $($selectedRepo.full_name)" -ForegroundColor Green
                                        
                                        # Get branches for the selected repository
                                        try {
                                            $headers = @{
                                                'Authorization' = "token $githubToken"
                                                'Accept'        = 'application/vnd.github.v3+json'
                                                'User-Agent'    = 'HomeLab-PowerShell'
                                            }
                                            
                                            Write-Host "Fetching branches..." -ForegroundColor Yellow
                                            $branchResponse = Invoke-RestMethod -Uri "$($selectedRepo.url)/branches" -Headers $headers -Method Get
                                            
                                            if ($branchResponse -and $branchResponse.Count -gt 0) {
                                                Write-Host ""
                                                Write-Host "Available branches:" -ForegroundColor Yellow
                                                for ($j = 0; $j -lt $branchResponse.Count; $j++) {
                                                    $branchName = $branchResponse[$j].name
                                                    $isDefault = if ($branchName -eq $selectedRepo.default_branch) { " (default)" } else { "" }
                                                    Write-Host "  $($j+1). $branchName$isDefault" -ForegroundColor White
                                                }
                                                
                                                $branchChoice = Read-Host "Select branch number or press Enter for default ($($selectedRepo.default_branch))"
                                                
                                                if ([string]::IsNullOrWhiteSpace($branchChoice)) {
                                                    $branch = $selectedRepo.default_branch
                                                }
                                                else {
                                                    try {
                                                        $branchIndex = [int]$branchChoice - 1
                                                        if ($branchIndex -ge 0 -and $branchIndex -lt $branchResponse.Count) {
                                                            $branch = $branchResponse[$branchIndex].name
                                                        }
                                                        else {
                                                            $branch = $selectedRepo.default_branch
                                                            Write-Host "Invalid selection. Using default branch: $branch" -ForegroundColor Yellow
                                                        }
                                                    }
                                                    catch {
                                                        $branch = $selectedRepo.default_branch
                                                        Write-Host "Invalid selection. Using default branch: $branch" -ForegroundColor Yellow
                                                    }
                                                }
                                            }
                                            else {
                                                $branch = $selectedRepo.default_branch
                                            }
                                        }
                                        catch {
                                            Write-Host "Could not fetch branches. Using default: $($selectedRepo.default_branch)" -ForegroundColor Yellow
                                            $branch = $selectedRepo.default_branch
                                        }
                                    }
                                    else {
                                        # Manual entry
                                        $repoUrl = Read-Host "Enter GitHub repository URL"
                                        $branch = Read-Host "Enter branch name [main]"
                                        if ([string]::IsNullOrWhiteSpace($branch)) {
                                            $branch = "main"
                                        }
                                    }
                                }
                                else {
                                    Write-Host "No repositories found. Enter repository details manually." -ForegroundColor Yellow
                                    $repoUrl = Read-Host "Enter GitHub repository URL"
                                    $branch = Read-Host "Enter branch name [main]"
                                    if ([string]::IsNullOrWhiteSpace($branch)) {
                                        $branch = "main"
                                    }
                                }
                            }
                            else {
                                # No token available, manual entry
                                $repoUrl = Read-Host "Enter GitHub repository URL"
                                $branch = Read-Host "Enter branch name [main]"
                                if ([string]::IsNullOrWhiteSpace($branch)) {
                                    $branch = "main"
                                }
                            }
                            
                            if ([string]::IsNullOrWhiteSpace($repoUrl)) {
                                Write-Host "GitHub repository URL is required" -ForegroundColor Red
                                break
                            }
                        }
                        else {
                            Write-Host "Invalid choice" -ForegroundColor Red
                            break
                        }
                        
                        # Ask for custom domain
                        $useDomain = Read-Host "Configure custom domain? (y/n)"
                        $customDomain = $null
                        $subdomain = $null
                        
                        if ($useDomain -eq "y") {
                            $customDomain = Read-Host "Enter domain (e.g., example.com)"
                            $subdomain = Read-Host "Enter subdomain (e.g., www)"
                        }
                        
                        # Confirm deployment
                        Write-Host ""
                        Write-Host "Ready to analyze and deploy:" -ForegroundColor Cyan
                        Write-Host "  Type: Auto-Detect" -ForegroundColor White
                        Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
                        Write-Host "  App Name: $appName" -ForegroundColor White
                        Write-Host "  Subscription: $subscriptionId" -ForegroundColor White
                        
                        if ($projectPath) {
                            Write-Host "  Source: Local Project Path" -ForegroundColor White
                            Write-Host "  Project Path: $projectPath" -ForegroundColor White
                        }
                        
                        if ($repoUrl) {
                            Write-Host "  Source: GitHub Repository" -ForegroundColor White
                            Write-Host "  Repository URL: $repoUrl" -ForegroundColor White
                            Write-Host "  Branch: $branch" -ForegroundColor White
                        }
                        
                        if ($customDomain) {
                            Write-Host "  Domain: $subdomain.$customDomain" -ForegroundColor White
                        }
                        
                        Write-Host ""
                        $confirm = Read-Host "Proceed with analysis and deployment? (y/n)"
                        
                        if ($confirm -eq "y") {
                            # Build params
                            $params = @{
                                DeploymentType = "auto"
                                ResourceGroup  = $resourceGroup
                                AppName        = $appName
                                SubscriptionId = $subscriptionId
                            }
                            
                            # Add source parameters
                            if ($projectPath) {
                                $params.ProjectPath = $projectPath
                            }
                            
                            if ($repoUrl) {
                                $params.RepoUrl = $repoUrl
                                $params.Branch = $branch
                                
                                # Check if GitHub token is available and if so, add it
                                if ($env:GITHUB_TOKEN) {
                                    $params.GitHubToken = $env:GITHUB_TOKEN
                                }
                            }
                            
                            if ($customDomain) {
                                $params.CustomDomain = $customDomain
                            }
                            
                            if ($subdomain) {
                                $params.Subdomain = $subdomain
                            }
                            
                            # Use our direct deployment function that's embedded in the script
                            try {
                                Write-Host "Starting deployment process..." -ForegroundColor Yellow
                                
                                # Source our direct deployment script
                                $directDeployPath = Join-Path -Path $PSScriptRoot -ChildPath "Direct-Deploy.ps1"
                                if (Test-Path $directDeployPath) {
                                    . $directDeployPath
                                }
                                else {
                                    throw "Direct deployment script not found at: $directDeployPath"
                                }
                                
                                # Ensure GitHub token is properly handled
                                if ($env:GITHUB_TOKEN -and $repoUrl) {
                                    $params.GitHubToken = $env:GITHUB_TOKEN
                                }
                                
                                # Now execute direct deployment
                                Write-Host "Executing deployment..." -ForegroundColor Yellow
                                Deploy-Website-Direct @params
                                Write-Host "Deployment completed successfully!" -ForegroundColor Green
                            }
                            catch {
                                Write-Host "Deployment failed:" -ForegroundColor Red
                                Write-Host $_.Exception.Message -ForegroundColor Red
                                
                                if ($_.Exception.InnerException) {
                                    Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
                                }
                                
                                # Provide guidance for common errors
                                Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
                                Write-Host "1. Check if Az PowerShell modules are installed: Install-Module -Name Az -AllowClobber" -ForegroundColor White
                                Write-Host "2. Ensure you're logged into Azure: Connect-AzAccount" -ForegroundColor White
                                Write-Host "3. Verify you have permissions in the selected subscription" -ForegroundColor White
                            }
                        }
                        else {
                            Write-Host "Deployment cancelled." -ForegroundColor Yellow
                        }
                    }
                    "4" {
                        # Return to main menu
                        return
                    }
                    default {
                        Write-Host "Invalid choice. Please select 1-4." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                
                if ($choice -in @("1", "2", "3")) {
                    Write-Host ""
                    Read-Host "Press Enter to return to Website Deployment menu"
                    Clear-Host
                }
            } while ($choice -ne "4")
        }
        "2" {
            Write-Host "Starting VPN Management..." -ForegroundColor Green
            if (Import-HomeLabModule) {
                Start-HomeLab
            }
            else {
                Write-Host "Failed to start HomeLab environment." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
        "3" {
            Write-Host "Starting DNS Management..." -ForegroundColor Green
            if (Import-HomeLabModule) {
                Start-HomeLab
            }
            else {
                Write-Host "Failed to start HomeLab environment." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
        "4" {
            Write-Host "Starting Monitoring & Alerts..." -ForegroundColor Green
            if (Import-HomeLabModule) {
                Start-HomeLab
            }
            else {
                Write-Host "Failed to start HomeLab environment." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
        "5" {
            Write-Host "Starting Full HomeLab Menu..." -ForegroundColor Green
            if (Import-HomeLabModule) {
                Start-HomeLab
            }
            else {
                Write-Host "Failed to start HomeLab environment." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
        "6" {
            Show-DocumentationMenu
        }
        "7" {
            Write-Host "Thank you for using HomeLab!" -ForegroundColor Green
            exit
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep 2
        }
    }
} while ($true)