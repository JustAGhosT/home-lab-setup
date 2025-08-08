function Show-DeploymentTypeInfo {
    <#
    .SYNOPSIS
        Displays information about deployment types to help users choose the right one.
    
    .DESCRIPTION
        This function displays detailed information about static web apps and app service
        deployment types, including use cases, characteristics, and pricing.
    
    .PARAMETER DeploymentType
        Optional. If specified, shows information only for the specified deployment type.
        Valid values are "static" and "appservice".
    
    .EXAMPLE
        Show-DeploymentTypeInfo
        
    .EXAMPLE
        Show-DeploymentTypeInfo -DeploymentType "static"
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("static", "appservice")]
        [string]$DeploymentType
    )
    
    # Static Web App information
    $staticWebAppInfo = @{
        Description = "Use for static sites, SPAs, JAMstack apps"
        UseCases = @(
            "React/Vue/Angular apps",
            "Static HTML/CSS/JS sites",
            "JAMstack applications",
            "Documentation sites",
            "Blogs"
        )
        Characteristics = @{
            ServerSideRendering = $false
            BackendAPIs = $false
            DatabaseConnections = $false
            StaticFilesOnly = $true
        }
        AzureResources = @(
            "Azure Static Web Apps",
            "Azure CDN (optional)",
            "Azure DNS (for custom domains)"
        )
        Pricing = "Free tier available, pay-as-you-go"
        AutoDetectFiles = @(
            "index.html",
            "build/index.html",
            "dist/index.html",
            "public/index.html"
        )
    }
    
    # App Service information
    $appServiceInfo = @{
        Description = "Use for dynamic web applications with server-side logic"
        UseCases = @(
            "Node.js/Express applications",
            "Python/Django/Flask apps",
            ".NET applications",
            "PHP applications",
            "Applications with APIs"
        )
        Characteristics = @{
            ServerSideRendering = $true
            BackendAPIs = $true
            DatabaseConnections = $true
            DynamicContent = $true
        }
        AzureResources = @(
            "Azure App Service",
            "App Service Plan",
            "Azure Application Insights (optional)",
            "Azure DNS (for custom domains)"
        )
        Pricing = "Starts from Basic tier, various plans available"
        AutoDetectFiles = @(
            "package.json (with server frameworks)",
            "requirements.txt",
            "wsgi.py",
            "asgi.py",
            "manage.py",
            "*.csproj",
            "Program.cs"
        )
    }
    
    # Decision matrix
    $decisionMatrix = @(
        @{
            Question = "Does your app need server-side processing?"
            StaticAnswer = "No"
            AppServiceAnswer = "Yes"
        },
        @{
            Question = "Do you need to connect to databases?"
            StaticAnswer = "No"
            AppServiceAnswer = "Yes"
        },
        @{
            Question = "Do you have API endpoints?"
            StaticAnswer = "No (or use Azure Functions)"
            AppServiceAnswer = "Yes"
        },
        @{
            Question = "Is your content pre-built/static?"
            StaticAnswer = "Yes"
            AppServiceAnswer = "No"
        },
        @{
            Question = "Do you need custom runtime environments?"
            StaticAnswer = "No"
            AppServiceAnswer = "Yes"
        }
    )
    
    # Display information based on deployment type
    if (-not $DeploymentType -or $DeploymentType -eq "static") {
        Write-Host "`n=== Static Web App ===" -ForegroundColor Cyan
        Write-Host "Description: $($staticWebAppInfo.Description)" -ForegroundColor White
        
        Write-Host "`nUse Cases:" -ForegroundColor Yellow
        foreach ($useCase in $staticWebAppInfo.UseCases) {
            Write-Host "  - $useCase" -ForegroundColor White
        }
        
        Write-Host "`nCharacteristics:" -ForegroundColor Yellow
        Write-Host "  - Server-side rendering: $($staticWebAppInfo.Characteristics.ServerSideRendering)" -ForegroundColor White
        Write-Host "  - Backend APIs: $($staticWebAppInfo.Characteristics.BackendAPIs)" -ForegroundColor White
        Write-Host "  - Database connections: $($staticWebAppInfo.Characteristics.DatabaseConnections)" -ForegroundColor White
        Write-Host "  - Static files only: $($staticWebAppInfo.Characteristics.StaticFilesOnly)" -ForegroundColor White
        
        Write-Host "`nAzure Resources:" -ForegroundColor Yellow
        foreach ($resource in $staticWebAppInfo.AzureResources) {
            Write-Host "  - $resource" -ForegroundColor White
        }
        
        Write-Host "`nPricing: $($staticWebAppInfo.Pricing)" -ForegroundColor Yellow
        
        Write-Host "`nAuto-detect Files:" -ForegroundColor Yellow
        foreach ($file in $staticWebAppInfo.AutoDetectFiles) {
            Write-Host "  - $file" -ForegroundColor White
        }
    }
    
    if ((-not $DeploymentType -or $DeploymentType -eq "appservice") -and (-not $DeploymentType -or $DeploymentType -eq "static")) {
        Write-Host "`n" # Add spacing between sections
    }
    
    if (-not $DeploymentType -or $DeploymentType -eq "appservice") {
        Write-Host "`n=== App Service ===" -ForegroundColor Magenta
        Write-Host "Description: $($appServiceInfo.Description)" -ForegroundColor White
        
        Write-Host "`nUse Cases:" -ForegroundColor Yellow
        foreach ($useCase in $appServiceInfo.UseCases) {
            Write-Host "  - $useCase" -ForegroundColor White
        }
        
        Write-Host "`nCharacteristics:" -ForegroundColor Yellow
        Write-Host "  - Server-side rendering: $($appServiceInfo.Characteristics.ServerSideRendering)" -ForegroundColor White
        Write-Host "  - Backend APIs: $($appServiceInfo.Characteristics.BackendAPIs)" -ForegroundColor White
        Write-Host "  - Database connections: $($appServiceInfo.Characteristics.DatabaseConnections)" -ForegroundColor White
        Write-Host "  - Dynamic content: $($appServiceInfo.Characteristics.DynamicContent)" -ForegroundColor White
        
        Write-Host "`nAzure Resources:" -ForegroundColor Yellow
        foreach ($resource in $appServiceInfo.AzureResources) {
            Write-Host "  - $resource" -ForegroundColor White
        }
        
        Write-Host "`nPricing: $($appServiceInfo.Pricing)" -ForegroundColor Yellow
        
        Write-Host "`nAuto-detect Files:" -ForegroundColor Yellow
        foreach ($file in $appServiceInfo.AutoDetectFiles) {
            Write-Host "  - $file" -ForegroundColor White
        }
    }
    
    # Display decision matrix if both deployment types are shown
    if (-not $DeploymentType) {
        Write-Host "`n=== Decision Matrix ===" -ForegroundColor Green
        
        foreach ($decision in $decisionMatrix) {
            Write-Host "`nQuestion: $($decision.Question)" -ForegroundColor Yellow
            Write-Host "  - Static Web App: $($decision.StaticAnswer)" -ForegroundColor Cyan
            Write-Host "  - App Service: $($decision.AppServiceAnswer)" -ForegroundColor Magenta
        }
    }
    
    Write-Host "`nFor more information, see the Website Deployment Guide: docs/WEBSITE-DEPLOYMENT.md" -ForegroundColor Green
}