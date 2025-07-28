function Select-ProjectFolder {
    <#
    .SYNOPSIS
        Opens a folder browser dialog to select a project folder.
    
    .DESCRIPTION
        This function displays a folder browser dialog to allow the user to select a project folder.
    
    .EXAMPLE
        $folderPath = Select-ProjectFolder
    #>
    [CmdletBinding()]
    param()
    
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the project folder to deploy"
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    
    return $null
}

function Deploy-Website {
    <#
    .SYNOPSIS
        Deploys a website to Azure using either Static Web Apps or App Service.
    
    .DESCRIPTION
        This function deploys a website to Azure based on the specified parameters.
        It supports both Static Web Apps and App Service deployments.
    
    .PARAMETER DeploymentType
        Type of deployment (static|appservice). Default is static.
    
    .PARAMETER Subdomain
        Subdomain for the application (e.g., myapp for myapp.yourdomain.com).
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER Location
        Azure region. Default is eastus.
    
    .PARAMETER AppName
        Application name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER CustomDomain
        Custom domain (e.g., yourdomain.com).
    
    .PARAMETER GitHubToken
        GitHub personal access token.
    
    .PARAMETER RepoUrl
        GitHub repository URL.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .EXAMPLE
        Deploy-Website -DeploymentType static -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType = "static",
        
        [Parameter()]
        [string]$Subdomain,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter()]
        [string]$Location = "eastus",
        
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$GitHubToken,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [string]$ProjectPath
    )
    
    # Function to check if Azure PowerShell is installed and logged in
    
    # Function to check if Azure PowerShell is installed and logged in
    function Test-AzurePowerShell {
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Write-Error "Error: Azure PowerShell is not installed"
            Write-Host "Please install Azure PowerShell: Install-Module -Name Az -AllowClobber -Force"
            return $false
        }

        try {
            $context = Get-AzContext
            if (-not $context) {
                Write-Error "Error: Not logged in to Azure"
                Write-Host "Please run: Connect-AzAccount"
                return $false
            }
        }
        catch {
            Write-Error "Error: Not logged in to Azure"
            Write-Host "Please run: Connect-AzAccount"
            return $false
        }
        
        return $true
    }
    
    # Function to determine deployment type based on project characteristics
    function Get-DeploymentType {
        param (
            [string]$Path
        )
        
        # Check for backend indicators
        if (Test-Path -Path "$Path\package.json") {
            $packageJson = Get-Content -Path "$Path\package.json" -Raw | ConvertFrom-Json
            if ($packageJson.dependencies -and 
                ($packageJson.dependencies.express -or 
                 $packageJson.dependencies.koa -or 
                 $packageJson.dependencies.fastify -or 
                 $packageJson.dependencies.hapi)) {
                return "appservice"
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
        
        # Default to static if unclear
        return "static"
    }
    
    # Function to create resource group if it doesn't exist
    function New-ResourceGroupIfNotExists {
        param (
            [string]$ResourceGroupName,
            [string]$Location
        )
        
        Write-Host "Creating resource group: $ResourceGroupName"
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        
        if (-not $resourceGroup) {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        }
    }
    
    # Function to deploy static web app
    function Deploy-StaticWebApp {
        param (
            [string]$AppName,
            [string]$ResourceGroup,
            [string]$RepoUrl,
            [string]$Branch,
            [string]$GitHubToken,
            [string]$Location,
            [string]$CustomDomain,
            [string]$Subdomain
        )
        
        Write-Host "Deploying Azure Static Web App: $AppName"
        
        # Create the static web app
        try {
            $staticWebApp = New-AzStaticWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -RepositoryUrl $RepoUrl -Branch $Branch -RepositoryToken $GitHubToken -Sku Free -ErrorAction Stop
            Write-Host "Static Web App created successfully: $AppName" -ForegroundColor Green
        } catch {
            Write-Error "Failed to create Static Web App: $_"
            return $null
        }
        
        # Configure custom domain if provided
        if ($CustomDomain -and $Subdomain) {
            $domain = "$Subdomain.$CustomDomain"
            try {
                Configure-CustomDomainStatic -AppName $AppName -ResourceGroup $ResourceGroup -Domain $domain
            } catch {
                Write-Error "Failed to configure custom domain: $_"
                Write-Warning "Static Web App was created but custom domain configuration failed"
            }
        }
        
        return $staticWebApp
    }
    
    # Function to deploy app service
    function Deploy-AppService {
        param (
            [string]$AppName,
            [string]$ResourceGroup,
            [string]$Location,
            [string]$RepoUrl,
            [string]$Branch,
            [string]$GitHubToken,
            [string]$CustomDomain,
            [string]$Subdomain
        )
        
        Write-Host "Deploying Azure App Service: $AppName"

        # Create app service plan
        $planName = "$AppName-plan"
        try {
            Write-Host "Creating App Service Plan: $planName" -ForegroundColor Yellow
            $appServicePlan = New-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic -WorkerSize Small -Linux -ErrorAction Stop
            Write-Host "Successfully created App Service Plan: $planName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create App Service Plan '$planName': $($_.Exception.Message)"
            throw
        }

        # Create web app
        try {
            Write-Host "Creating Web App: $AppName" -ForegroundColor Yellow
            $webApp = New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan $planName -RuntimeStack "NODE|18-lts" -ErrorAction Stop
            Write-Host "Successfully created Web App: $AppName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create Web App '$AppName': $($_.Exception.Message)"

            # Cleanup: Remove the app service plan if web app creation failed
            try {
                Write-Host "Cleaning up App Service Plan due to Web App creation failure..." -ForegroundColor Yellow
                Remove-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -Force -ErrorAction SilentlyContinue
                Write-Host "App Service Plan cleanup completed" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Failed to cleanup App Service Plan '$planName': $($_.Exception.Message)"
            }

            throw
        }
        
        # Configure deployment from GitHub
        if ($RepoUrl -and $GitHubToken) {
            $props = @{
                repoUrl = $RepoUrl
                branch = $Branch
                isManualIntegration = $true
            }
            
            Set-AzResource -ResourceId "$($webApp.Id)/sourcecontrols/web" -Properties $props -ApiVersion 2015-08-01 -Force
        }
        
        # Configure custom domain if provided
        if ($CustomDomain -and $Subdomain) {
            $domain = "$Subdomain.$CustomDomain"
            Configure-CustomDomainAppService -AppName $AppName -ResourceGroup $ResourceGroup -Domain $domain
        }
        
        return $webApp
    }
    
    # Function to configure custom domain for static web app
    function Configure-CustomDomainStatic {
        param (
            [string]$AppName,
            [string]$ResourceGroup,
            [string]$Domain
        )
        
        Write-Host "Configuring custom domain for Static Web App: $Domain"
        
        # Add custom domain
        New-AzStaticWebAppCustomDomain -Name $AppName -ResourceGroupName $ResourceGroup -DomainName $Domain
        
        $staticWebApp = Get-AzStaticWebApp -Name $AppName -ResourceGroupName $ResourceGroup
        
        Write-Host "Custom domain configured. Please update your DNS records:"
        Write-Host "Type: CNAME"
        Write-Host "Name: $(($Domain -split '\.')[0])"
        Write-Host "Value: $($staticWebApp.DefaultHostname)"
    }
    
    # Function to configure custom domain for app service
    function Configure-CustomDomainAppService {
        param (
            [string]$AppName,
            [string]$ResourceGroup,
            [string]$Domain
        )
        
        Write-Host "Configuring custom domain for App Service: $Domain"
        
        # Add custom domain
        Set-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -HostNames @($Domain, "$AppName.azurewebsites.net")
        
        Write-Host "Custom domain configured. Please update your DNS records:"
        Write-Host "Type: CNAME"
        Write-Host "Name: $(($Domain -split '\.')[0])"
        Write-Host "Value: $AppName.azurewebsites.net"
    }
    
    # Main execution
    Write-Host "Starting Azure website deployment..."
    Write-Host "Deployment type: $DeploymentType"
    Write-Host "Application name: $AppName"
    Write-Host "Resource group: $ResourceGroup"
    Write-Host "Location: $Location"
    
    # Check prerequisites
    if (-not (Test-AzurePowerShell)) {
        return
    }
    
    # Set subscription
    Set-AzContext -SubscriptionId $SubscriptionId
    
    # Create resource group
    New-ResourceGroupIfNotExists -ResourceGroupName $ResourceGroup -Location $Location
    
    # Auto-detect deployment type if specified
    if ($DeploymentType -eq "auto" -and $ProjectPath) {
        $DeploymentType = Get-DeploymentType -Path $ProjectPath
        Write-Host "Auto-detected deployment type: $DeploymentType"
    }
    
    # Deploy based on type
    switch ($DeploymentType) {
        "static" {
            $result = Deploy-StaticWebApp -AppName $AppName -ResourceGroup $ResourceGroup -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -Location $Location -CustomDomain $CustomDomain -Subdomain $Subdomain
        }
        "appservice" {
            $result = Deploy-AppService -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -CustomDomain $CustomDomain -Subdomain $Subdomain
        }
        default {
            Write-Error "Error: Invalid deployment type. Use 'static' or 'appservice'"
            return
        }
    }
    
    # Add GitHub workflow files if project path is provided
    if ($ProjectPath) {
        $addWorkflowsPrompt = Read-Host "Would you like to add GitHub workflow files for automatic deployment? (y/n)"
        if ($addWorkflowsPrompt -eq "y") {
            Write-Host "Adding GitHub workflow files for automatic deployment..." -ForegroundColor Yellow
            $workflowParams = @{
                ProjectPath = $ProjectPath
                DeploymentType = $DeploymentType
            }
            
            if ($CustomDomain) {
                $workflowParams.CustomDomain = $CustomDomain
            }
            
            Add-GitHubWorkflows @workflowParams
            Write-Host "GitHub workflow files added successfully!" -ForegroundColor Green
            Write-Host "You can now use GitHub Actions to deploy this project automatically." -ForegroundColor Green
        }
    }
    
    Write-Host "Deployment completed successfully!"
    return $result
}