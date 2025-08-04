# Emergency direct replacement for website menu to bypass all the complex logic

function Show-WebsiteMenuDirect {
    [CmdletBinding()]
    param()
    
    # Guaranteed to work hashtable-based menu
    $menuItems = @{
        "1" = "Deploy Static Website"
        "2" = "Deploy App Service Website" 
        "3" = "Auto-Detect and Deploy Website"
        "4" = "Configure Custom Domain"
        "5" = "Return to Main Menu"
    }
    
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
    
    # Get user choice
    Write-Host ""
    $choice = Read-Host "Select an option (1-5)"
    
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
            Configure-SimpleCustomDomain
        }
        "5" {
            # Return to main menu
            return
        }
        default {
            Write-Host "Invalid choice. Try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Show-WebsiteMenuDirect
        }
    }
    
    # Return to this menu after function completes
    Read-Host "Press Enter to continue"
    Show-WebsiteMenuDirect
}

# Simple deployment functions that don't rely on complex handlers

function Deploy-SimpleStaticWebsite {
    Clear-Host
    Write-Host "=== Deploy Static Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters
    $resourceGroup = Read-Host "Enter Resource Group name"
    $appName = Read-Host "Enter App Name"
    $subscriptionId = Read-Host "Enter Subscription ID"
    
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
        ResourceGroup = $resourceGroup
        AppName = $appName
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

function Deploy-SimpleAppServiceWebsite {
    Clear-Host
    Write-Host "=== Deploy App Service Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters
    $resourceGroup = Read-Host "Enter Resource Group name"
    $appName = Read-Host "Enter App Name"
    $subscriptionId = Read-Host "Enter Subscription ID"
    
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
        ResourceGroup = $resourceGroup
        AppName = $appName
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

function Deploy-SimpleAutoDetectWebsite {
    Clear-Host
    Write-Host "=== Auto-Detect and Deploy Website ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Get required parameters
    $resourceGroup = Read-Host "Enter Resource Group name"
    $appName = Read-Host "Enter App Name"
    $subscriptionId = Read-Host "Enter Subscription ID"
    $projectPath = Read-Host "Enter project path (required for auto-detection)"
    
    if (-not $projectPath) {
        Write-Host "Project path is required for auto-detection." -ForegroundColor Red
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
        ResourceGroup = $resourceGroup
        AppName = $appName
        SubscriptionId = $subscriptionId
        ProjectPath = $projectPath
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
}

function Configure-SimpleCustomDomain {
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