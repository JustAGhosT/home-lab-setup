function Deploy-Azure {
    <#
    .SYNOPSIS
        Deploys a website to Azure using Static Web Apps or App Service.
    
    .DESCRIPTION
        This function deploys a website to Azure using either Static Web Apps for JAMstack and static sites
        or App Service for full-stack applications with .NET, Node.js, Python, etc.
    
    .PARAMETER AppName
        Application name for the Azure resources.
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER Location
        Azure region for deployment.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER DeploymentType
        Type of deployment (static|appservice|auto). Default is auto.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER Subdomain
        Subdomain for the application.
    
    .PARAMETER GitHubToken
        GitHub personal access token for repository deployment.
    
    .PARAMETER RepoUrl
        GitHub repository URL for automatic deployments.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .PARAMETER ProjectPath
        Path to the project directory for local deployment.
    
    .EXAMPLE
        Deploy-Azure -AppName "my-app" -ResourceGroup "my-rg" -Location "westeurope" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter()]
        [string]$Location = "westeurope",
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType = "auto",
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$Subdomain,
        
        [Parameter()]
        [SecureString]$GitHubToken,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [string]$ProjectPath
    )
    
    Write-Host "=== Deploying to Azure ===" -ForegroundColor Cyan
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "Location: $Location" -ForegroundColor White
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Check Azure PowerShell prerequisites
    Write-Host "Step 1/6: Checking Azure PowerShell prerequisites..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Error "Error: Azure PowerShell is not installed"
        Write-Host "Please install Azure PowerShell: Install-Module -Name Az -AllowClobber -Force" -ForegroundColor Yellow
        throw "Azure PowerShell module not found"
    }

    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Error "Error: Not logged in to Azure"
            Write-Host "Please run: Connect-AzAccount" -ForegroundColor Yellow
            throw "Azure authentication required"
        }
        Write-Host "Azure authentication verified." -ForegroundColor Green
    }
    catch {
        Write-Error "Error: Azure authentication failed"
        Write-Host "Please run: Connect-AzAccount" -ForegroundColor Yellow
        throw "Azure authentication failed"
    }
    
    # Step 2: Set Azure subscription
    Write-Host "Step 2/6: Setting Azure subscription..." -ForegroundColor Cyan
    try {
        $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Host "Successfully set subscription context: $($context.Subscription.Name)" -ForegroundColor Green
    }
    catch [Microsoft.Azure.Commands.Profile.Errors.AzPSResourceNotFoundCloudException] {
        Write-Error "Subscription ID '$SubscriptionId' not found. Please verify the subscription ID is correct and you have access to it."
        Write-Host "To list available subscriptions, run: Get-AzSubscription" -ForegroundColor Cyan
        throw "Invalid subscription ID"
    }
    catch [Microsoft.Azure.Commands.Profile.Errors.AzPSAuthenticationFailedException] {
        Write-Error "Authentication failed. Please run 'Connect-AzAccount' to authenticate with Azure."
        throw "Azure authentication failed"
    }
    catch {
        Write-Error "Failed to set Azure subscription context: $($_.Exception.Message)"
        Write-Host "Please verify your subscription ID and authentication status." -ForegroundColor Yellow
        throw "Failed to set subscription context"
    }
    
    # Step 3: Create resource group
    Write-Host "Step 3/6: Creating resource group..." -ForegroundColor Cyan
    try {
        $existingRG = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $existingRG) {
            Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor White
            New-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction Stop
            Write-Host "Resource group created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Resource group '$ResourceGroup' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create resource group: $($_.Exception.Message)"
    }
    
    # Step 4: Auto-detect deployment type if specified
    Write-Host "Step 4/6: Determining deployment type..." -ForegroundColor Cyan
    if ($DeploymentType -eq "auto" -and $ProjectPath) {
        $DeploymentType = Get-DeploymentType -Path $ProjectPath
        Write-Host "Auto-detected deployment type: $DeploymentType" -ForegroundColor Green
    }
    elseif ($DeploymentType -eq "auto") {
        Write-Host "Auto-detection requires ProjectPath. Defaulting to static deployment." -ForegroundColor Yellow
        $DeploymentType = "static"
    }
    
    # Step 5: Deploy based on type
    Write-Host "Step 5/6: Deploying to Azure..." -ForegroundColor Cyan
    try {
        switch ($DeploymentType) {
            "static" {
                Write-Host "Deploying Static Web App..." -ForegroundColor White
                $result = Deploy-StaticWebApp -AppName $AppName -ResourceGroup $ResourceGroup -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -Location $Location -CustomDomain $CustomDomain -Subdomain $Subdomain
            }
            "appservice" {
                Write-Host "Deploying App Service..." -ForegroundColor White
                $result = Deploy-AppService -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -CustomDomain $CustomDomain -Subdomain $Subdomain
            }
            default {
                throw "Invalid deployment type: $DeploymentType. Use 'static' or 'appservice'"
            }
        }
    }
    catch {
        throw "Failed to deploy to Azure: $($_.Exception.Message)"
    }
    
    # Step 6: Configure custom domain if provided
    Write-Host "Step 6/6: Configuring custom domain..." -ForegroundColor Cyan
    if ($CustomDomain) {
        try {
            if ($DeploymentType -eq "static") {
                Configure-CustomDomainStaticWebApp -AppName $AppName -ResourceGroup $ResourceGroup -Domain $CustomDomain
            }
            else {
                Configure-CustomDomainAppService -AppName $AppName -ResourceGroup $ResourceGroup -Domain $CustomDomain
            }
            Write-Host "Custom domain configured successfully." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to configure custom domain: $($_.Exception.Message)"
        }
    }
    
    # Return deployment information
    return @{
        Success       = $true
        DeploymentUrl = $result.Url
        AppName       = $AppName
        Platform      = "Azure"
        Service       = if ($DeploymentType -eq "static") { "Static Web Apps" } else { "App Service" }
        Region        = $Location
        ResourceGroup = $ResourceGroup
        CustomDomain  = $CustomDomain
    }
}

# Helper function to determine deployment type based on project characteristics
function Get-DeploymentType {
    param (
        [string]$Path
    )
    
    # Check for backend indicators
    if (Test-Path -Path "$Path\package.json") {
        try {
            Write-Verbose "Reading package.json from: $Path\package.json"
            $packageJsonContent = Get-Content -Path "$Path\package.json" -Raw -ErrorAction Stop
            $packageJson = ConvertFrom-Json $packageJsonContent -ErrorAction Stop

            if ($packageJson.dependencies -and
                ($packageJson.dependencies.express -or
                $packageJson.dependencies.koa -or
                $packageJson.dependencies.fastify -or
                $packageJson.dependencies.hapi)) {
                Write-Verbose "Detected backend Node.js framework, using appservice deployment"
                return "appservice"
            }
        }
        catch [System.ArgumentException] {
            Write-Warning "Failed to parse package.json: Invalid JSON format. $($_.Exception.Message)"
            Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
        }
        catch [System.IO.IOException] {
            Write-Warning "Failed to read package.json: File access error. $($_.Exception.Message)"
            Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Failed to process package.json: $($_.Exception.Message)"
            Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
        }
    }
    
    if ((Test-Path -Path "$Path\requirements.txt") -or 
        (Test-Path -Path "$Path\Pipfile") -or 
        (Test-Path -Path "$Path\setup.py")) {
        if ((Test-Path -Path "$Path\wsgi.py") -or 
            (Test-Path -Path "$Path\asgi.py") -or 
            (Test-Path -Path "$Path\manage.py")) {
            return "appservice"
        }
    }
    
    if ((Get-ChildItem -Path $Path -Filter "*.csproj" -Recurse) -or 
        (Test-Path -Path "$Path\Program.cs") -or 
        (Test-Path -Path "$Path\Startup.cs")) {
        return "appservice"
    }
    
    # Check for static site indicators
    if ((Test-Path -Path "$Path\index.html") -or 
        (Test-Path -Path "$Path\build\index.html") -or 
        (Test-Path -Path "$Path\dist\index.html")) {
        return "static"
    }
    
    # Default to static if no clear indicators
    return "static"
}

# Helper function to deploy Static Web App
function Deploy-StaticWebApp {
    param (
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$RepoUrl,
        [string]$Branch,
        [SecureString]$GitHubToken,
        [string]$Location,
        [string]$CustomDomain,
        [string]$Subdomain
    )
    
    Write-Host "Deploying Azure Static Web App..." -ForegroundColor Cyan
    
    try {
        # Create Static Web App
        $staticWebAppParams = @{
            Name              = $AppName
            ResourceGroupName = $ResourceGroup
            Location          = $Location
        }
        
        if ($RepoUrl) {
            $staticWebAppParams.Source = $RepoUrl
            $staticWebAppParams.Branch = $Branch
            if ($GitHubToken) {
                $staticWebAppParams.Token = $GitHubToken
            }
        }
        
        $staticWebApp = New-AzStaticWebApp @staticWebAppParams -ErrorAction Stop
        Write-Host "Static Web App created successfully!" -ForegroundColor Green
        
        return @{
            Url  = $staticWebApp.DefaultHostname
            Name = $staticWebApp.Name
        }
    }
    catch {
        throw "Failed to create Static Web App: $($_.Exception.Message)"
    }
}

# Helper function to deploy App Service
function Deploy-AppService {
    param (
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$Location,
        [string]$RepoUrl,
        [string]$Branch,
        [SecureString]$GitHubToken,
        [string]$CustomDomain,
        [string]$Subdomain
    )
    
    Write-Host "Deploying Azure App Service..." -ForegroundColor Cyan
    
    try {
        # Create App Service Plan
        $appServicePlanName = "$AppName-plan"
        $appServicePlan = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        
        if (-not $appServicePlan) {
            Write-Host "Creating App Service Plan..." -ForegroundColor White
            $appServicePlan = New-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $ResourceGroup -Location $Location -Tier "Basic" -WorkerSize "Small" -ErrorAction Stop
        }
        
        # Create Web App
        $webApp = Get-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        
        if (-not $webApp) {
            Write-Host "Creating Web App..." -ForegroundColor White
            $webApp = New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan $appServicePlan -ErrorAction Stop
        }
        
        # Configure deployment source if provided
        if ($RepoUrl) {
            Write-Host "Configuring deployment source..." -ForegroundColor White
            $deploymentSource = @{
                RepoUrl = $RepoUrl
                Branch  = $Branch
            }
            
            if ($GitHubToken) {
                $deploymentSource.Token = $GitHubToken
            }
            
            Set-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -SourceControl @deploymentSource -ErrorAction Stop
        }
        
        Write-Host "App Service created successfully!" -ForegroundColor Green
        
        return @{
            Url  = $webApp.DefaultHostName
            Name = $webApp.Name
        }
    }
    catch {
        throw "Failed to create App Service: $($_.Exception.Message)"
    }
}

# Helper function to configure custom domain for Static Web App
function Configure-CustomDomainStaticWebApp {
    param (
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$Domain
    )
    
    Write-Host "Configuring custom domain for Static Web App: $Domain" -ForegroundColor Cyan
    
    try {
        $staticWebApp = Get-AzStaticWebApp -Name $AppName -ResourceGroupName $ResourceGroup -ErrorAction Stop
        
        # Add custom domain
        Write-Host "Adding custom domain to Static Web App..." -ForegroundColor Yellow
        New-AzStaticWebAppCustomDomain -Name $AppName -ResourceGroupName $ResourceGroup -DomainName $Domain -ErrorAction Stop
        
        Write-Host "Custom domain configured successfully!" -ForegroundColor Green
        Write-Host "Please update your DNS records:" -ForegroundColor Cyan
        Write-Host "Type: CNAME" -ForegroundColor White
        Write-Host "Name: $(($Domain -split '\.')[0])" -ForegroundColor White
        Write-Host "Value: $($staticWebApp.DefaultHostname)" -ForegroundColor White
    }
    catch {
        throw "Failed to configure custom domain for Static Web App: $($_.Exception.Message)"
    }
}

# Helper function to configure custom domain for App Service
function Configure-CustomDomainAppService {
    param (
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$Domain
    )
    
    Write-Host "Configuring custom domain for App Service: $Domain" -ForegroundColor Cyan
    
    try {
        # Add custom domain
        Write-Host "Adding custom domain to App Service..." -ForegroundColor Yellow
        Set-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -HostNames @($Domain, "$AppName.azurewebsites.net") -ErrorAction Stop
        
        Write-Host "Custom domain configured successfully!" -ForegroundColor Green
        Write-Host "Please update your DNS records:" -ForegroundColor Cyan
        Write-Host "Type: CNAME" -ForegroundColor White
        Write-Host "Name: $(($Domain -split '\.')[0])" -ForegroundColor White
        Write-Host "Value: $AppName.azurewebsites.net" -ForegroundColor White
    }
    catch {
        throw "Failed to configure custom domain for App Service: $($_.Exception.Message)"
    }
} 