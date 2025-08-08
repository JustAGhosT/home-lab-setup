# Emergency direct replacement for website menu to bypass all the complex logic

<#
.SYNOPSIS
    Displays a simplified website deployment menu with direct deployment options.
.DESCRIPTION
    Provides a streamlined interface for website deployment without complex handlers.
#>
function Show-WebsiteMenuDirect {
    [CmdletBinding()]
    param()
    
    # Menu options for deployment
    
    do {
        # Clear host for clean display
        Clear-Host
        
        # Display title
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host "         WEBSITE DEPLOYMENT MENU           " -ForegroundColor Cyan
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Display menu items
        Write-Host "  [1] Deploy Static Website" -ForegroundColor White
        Write-Host "  [2] Deploy App Service Website" -ForegroundColor White
        Write-Host "  [3] Auto-Detect and Deploy Website" -ForegroundColor White
        Write-Host "  [4] Configure Custom Domain" -ForegroundColor White
        Write-Host "  [5] Return to Main Menu" -ForegroundColor Yellow
        
        # Get user choice with validation
        Write-Host ""
        $choice = Read-Host "Select an option (1-5)"
        
        # Validate input
        if ($choice -match '^[1-5]$') {
            # Process user choice without using complex handlers
            switch ($choice) {
                "1" {
                    Deploy-SimpleStaticWebsite
                }
                "2" {
                    Deploy-SimpleAppServiceWebsite
                }
                "3" {
                    Deploy-SimpleAutoDetectWebsite
                }
                "4" {
                    Set-SimpleCustomDomain
                }
                "5" {
                    # Return to main menu
                    return
                }
            }
            
            # Return to this menu after function completes
            Read-Host "Press Enter to continue"
        }
        else {
            Write-Host "Invalid choice. Please enter a number between 1 and 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } while ($true)
}

# Simple deployment functions that don't rely on complex handlers

<#
.SYNOPSIS
    Deploys a static website with simplified parameter collection.
.DESCRIPTION
    Collects deployment parameters and deploys a static website without complex handlers.
#>
function Deploy-SimpleStaticWebsite {
    Clear-Host
    Write-Host "=== Deploy Static Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters with validation
    do {
        $resourceGroup = Read-Host "Enter Resource Group name"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            Write-Host "Resource Group name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $appName = Read-Host "Enter App Name"
        if ([string]::IsNullOrWhiteSpace($appName)) {
            Write-Host "App Name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $subscriptionId = Read-Host "Enter Subscription ID"
        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
            Write-Host "Subscription ID cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        # Basic GUID format validation
        if ($subscriptionId -notmatch '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
            Write-Host "Invalid Subscription ID format. Please enter a valid GUID." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    # Ask about custom domain
    $useDomain = Read-Host "Configure custom domain? (y/n)"
    $customDomain = $null
    $subdomain = $null
    
    if ($useDomain -eq "y") {
        $customDomain = Read-Host "Enter domain (e.g., example.com)"
        $subdomain = Read-Host "Enter subdomain (e.g., www)"
    }
    
    # Ask about project path
    $useLocalPath = Read-Host "Deploy from local folder? (y/n)"
    $projectPath = $null
    
    if ($useLocalPath -eq "y") {
        $projectPath = Read-Host "Enter project path"
    }
    
    # Build parameters
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
    
    if ($projectPath) {
        $params.ProjectPath = $projectPath
    }
    
    # Show deployment summary
    Write-Host ""
    Write-Host "Deployment Summary:" -ForegroundColor Cyan
    Write-Host "Type: Static Web App" -ForegroundColor White
    Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
    Write-Host "App Name: $appName" -ForegroundColor White
    Write-Host "Subscription: $subscriptionId" -ForegroundColor White
    
    if ($customDomain) {
        Write-Host "Domain: $subdomain.$customDomain" -ForegroundColor White
    }
    
    if ($projectPath) {
        Write-Host "Project Path: $projectPath" -ForegroundColor White
    }
    
    # Confirm and deploy
    Write-Host ""
    $confirm = Read-Host "Proceed with deployment? (y/n)"
    
    if ($confirm -eq "y") {
        try {
            # Call the actual deployment function
            Write-Host "Deploying static website..." -ForegroundColor Yellow
            Deploy-Website @params
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Deploys an App Service website with simplified parameter collection.
.DESCRIPTION
    Collects deployment parameters and deploys an App Service website without complex handlers.
#>
function Deploy-SimpleAppServiceWebsite {
    Clear-Host
    Write-Host "=== Deploy App Service Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters with validation
    do {
        $resourceGroup = Read-Host "Enter Resource Group name"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            Write-Host "Resource Group name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $appName = Read-Host "Enter App Name"
        if ([string]::IsNullOrWhiteSpace($appName)) {
            Write-Host "App Name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $subscriptionId = Read-Host "Enter Subscription ID"
        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
            Write-Host "Subscription ID cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        # Basic GUID format validation
        if ($subscriptionId -notmatch '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
            Write-Host "Invalid Subscription ID format. Please enter a valid GUID." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    # Ask about custom domain
    $useDomain = Read-Host "Configure custom domain? (y/n)"
    $customDomain = $null
    $subdomain = $null
    
    if ($useDomain -eq "y") {
        $customDomain = Read-Host "Enter domain (e.g., example.com)"
        $subdomain = Read-Host "Enter subdomain (e.g., api)"
    }
    
    # Ask about project path
    $useLocalPath = Read-Host "Deploy from local folder? (y/n)"
    $projectPath = $null
    
    if ($useLocalPath -eq "y") {
        $projectPath = Read-Host "Enter project path"
    }
    
    # Build parameters
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
    
    if ($projectPath) {
        $params.ProjectPath = $projectPath
    }
    
    # Show deployment summary
    Write-Host ""
    Write-Host "Deployment Summary:" -ForegroundColor Cyan
    Write-Host "Type: App Service" -ForegroundColor White
    Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
    Write-Host "App Name: $appName" -ForegroundColor White
    Write-Host "Subscription: $subscriptionId" -ForegroundColor White
    
    if ($customDomain) {
        Write-Host "Domain: $subdomain.$customDomain" -ForegroundColor White
    }
    
    if ($projectPath) {
        Write-Host "Project Path: $projectPath" -ForegroundColor White
    }
    
    # Confirm and deploy
    Write-Host ""
    $confirm = Read-Host "Proceed with deployment? (y/n)"
    
    if ($confirm -eq "y") {
        try {
            # Call the actual deployment function
            Write-Host "Deploying App Service website..." -ForegroundColor Yellow
            Deploy-Website @params
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Auto-detects project type and deploys website with simplified parameter collection.
.DESCRIPTION
    Automatically detects the project type and deploys the website without complex handlers.
#>
function Deploy-SimpleAutoDetectWebsite {
    Clear-Host
    Write-Host "=== Auto-Detect and Deploy Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters with validation
    do {
        $resourceGroup = Read-Host "Enter Resource Group name"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            Write-Host "Resource Group name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $appName = Read-Host "Enter App Name"
        if ([string]::IsNullOrWhiteSpace($appName)) {
            Write-Host "App Name cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $subscriptionId = Read-Host "Enter Subscription ID"
        if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
            Write-Host "Subscription ID cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        # Basic GUID format validation
        if ($subscriptionId -notmatch '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
            Write-Host "Invalid Subscription ID format. Please enter a valid GUID." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    
    do {
        $projectPath = Read-Host "Enter project path (required for auto-detection)"
        if ([string]::IsNullOrWhiteSpace($projectPath)) {
            Write-Host "Project path is required for auto-detection. Please try again." -ForegroundColor Red
            continue
        }
        if (-not (Test-Path -Path $projectPath)) {
            Write-Host "Project path does not exist. Please enter a valid path." -ForegroundColor Red
            continue
        }
        break
    } while ($true)
    return
}
    
# Ask about custom domain
$useDomain = Read-Host "Configure custom domain? (y/n)"
$customDomain = $null
$subdomain = $null
    
if ($useDomain -eq "y") {
    $customDomain = Read-Host "Enter domain (e.g., example.com)"
    $subdomain = Read-Host "Enter subdomain (e.g., www)"
}
    
# Build parameters
$params = @{
    DeploymentType = "auto"
    ResourceGroup  = $resourceGroup
    AppName        = $appName
    SubscriptionId = $subscriptionId
    ProjectPath    = $projectPath
}
    
if ($customDomain) {
    $params.CustomDomain = $customDomain
}
    
if ($subdomain) {
    $params.Subdomain = $subdomain
}
    
# Show deployment summary
Write-Host ""
Write-Host "Deployment Summary:" -ForegroundColor Cyan
Write-Host "Type: Auto-Detect" -ForegroundColor White
Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "App Name: $appName" -ForegroundColor White
Write-Host "Subscription: $subscriptionId" -ForegroundColor White
Write-Host "Project Path: $projectPath" -ForegroundColor White
    
if ($customDomain) {
    Write-Host "Domain: $subdomain.$customDomain" -ForegroundColor White
}
    
# Confirm and deploy
Write-Host ""
$confirm = Read-Host "Proceed with deployment? (y/n)"
    
if ($confirm -eq "y") {
    try {
        # Call the actual deployment function
        Write-Host "Auto-detecting project type and deploying website..." -ForegroundColor Yellow
        Deploy-Website @params
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Configures custom domain for website deployment.
.DESCRIPTION
    Sets up custom domain configuration for static or app service websites.
#>
function Set-SimpleCustomDomain {
    Clear-Host
    Write-Host "=== Configure Custom Domain ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters
    $resourceGroup = Read-Host "Enter Resource Group name"
    $appName = Read-Host "Enter App Name"
    $customDomain = Read-Host "Enter domain (e.g., example.com)"
    $subdomain = Read-Host "Enter subdomain (e.g., www)"
    $websiteType = Read-Host "Website type (static/appservice)"
    
    if ($websiteType -ne "static" -and $websiteType -ne "appservice") {
        Write-Host "Invalid website type. Must be 'static' or 'appservice'." -ForegroundColor Red
        return
    }
    
    # Confirm and configure
    Write-Host ""
    Write-Host "Configuration Summary:" -ForegroundColor Cyan
    Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
    Write-Host "App Name: $appName" -ForegroundColor White
    Write-Host "Domain: $subdomain.$customDomain" -ForegroundColor White
    Write-Host "Website Type: $websiteType" -ForegroundColor White
    
    $confirm = Read-Host "Proceed with custom domain configuration? (y/n)"
    
    if ($confirm -eq "y") {
        try {
            # Call the appropriate function based on website type
            Write-Host "Configuring custom domain..." -ForegroundColor Yellow
            
            if ($websiteType -eq "static") {
                Configure-CustomDomainStatic -AppName $appName -ResourceGroup $resourceGroup -Domain "$subdomain.$customDomain"
            }
            else {
                Configure-CustomDomainAppService -AppName $appName -ResourceGroup $resourceGroup -Domain "$subdomain.$customDomain"
            }
            
            Write-Host "Custom domain configured successfully!" -ForegroundColor Green
            Write-Host "Please update your DNS records as instructed above." -ForegroundColor Yellow
        }
        catch {
            Write-Host "Custom domain configuration failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Configuration cancelled." -ForegroundColor Yellow
    }
}