function Get-DeploymentParameters {
    <#
    .SYNOPSIS
        Gets common deployment parameters for website deployments.
    
    .DESCRIPTION
        This function collects common deployment parameters such as resource group, app name,
        location, GitHub deployment options, and custom domain configuration.
    
    .PARAMETER DeploymentType
        The type of deployment (static, appservice, auto).
    
    .PARAMETER Config
        The configuration object containing subscription ID.
    
    .PARAMETER ProjectPath
        Optional. The project path if already selected.
    
    .EXAMPLE
        $params = Get-DeploymentParameters -DeploymentType "static" -Config $config
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    # Get deployment parameters with validation

    # Validate Resource Group Name (Azure naming rules)
    do {
        $resourceGroup = Read-Host "Enter resource group name"
        $isValidRG = $true
        $errorMessage = ""

        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            $isValidRG = $false
            $errorMessage = "Resource group name cannot be empty."
        }
        elseif ($resourceGroup.Length -lt 1 -or $resourceGroup.Length -gt 90) {
            $isValidRG = $false
            $errorMessage = "Resource group name must be 1-90 characters long."
        }
        elseif ($resourceGroup -notmatch '^[a-zA-Z0-9._\-()]+$') {
            $isValidRG = $false
            $errorMessage = "Resource group name can only contain alphanumeric characters, periods, hyphens, underscores, or parentheses."
        }
        elseif ($resourceGroup.EndsWith('.')) {
            $isValidRG = $false
            $errorMessage = "Resource group name cannot end with a period."
        }

        if (-not $isValidRG) {
            Write-Host "Invalid resource group name: $errorMessage" -ForegroundColor Red
            Write-Host "Please try again." -ForegroundColor Yellow
        }
    } while (-not $isValidRG)

    # Validate Application Name (Azure App Service naming rules)
    do {
        $appName = Read-Host "Enter application name"
        $isValidApp = $true
        $errorMessage = ""

        if ([string]::IsNullOrWhiteSpace($appName)) {
            $isValidApp = $false
            $errorMessage = "Application name cannot be empty."
        }
        elseif ($appName.Length -lt 1 -or $appName.Length -gt 60) {
            $isValidApp = $false
            $errorMessage = "Application name must be 1-60 characters long."
        }
        elseif ($appName -notmatch '^[a-zA-Z0-9\-]+$') {
            $isValidApp = $false
            $errorMessage = "Application name can only contain alphanumeric characters or hyphens."
        }

        if (-not $isValidApp) {
            Write-Host "Invalid application name: $errorMessage" -ForegroundColor Red
            Write-Host "Please try again." -ForegroundColor Yellow
        }
    } while (-not $isValidApp)

    # Get location with default
    $location = Read-Host "Enter location (default: eastus)"
    if ([string]::IsNullOrWhiteSpace($location)) { $location = "eastus" }
    
    $params = @{
        DeploymentType = $DeploymentType
        ResourceGroup  = $resourceGroup
        AppName        = $appName
        Location       = $location
        SubscriptionId = $Config.SubscriptionId
    }
    
    # Handle GitHub deployment if not auto-detect
    if ($DeploymentType -ne "auto") {
        $useGitHub = Read-Host "Deploy from GitHub? (y/n)"
        if ($useGitHub -eq "y") {
            $repoUrl = Read-Host "Enter GitHub repository URL"
            $branch = Read-Host "Enter branch name (default: main)"
            if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }
            
            # Securely capture GitHub token (keep as SecureString for security)
            $secureGitHubToken = Read-Host "Enter GitHub personal access token" -AsSecureString

            $params.RepoUrl = $repoUrl
            $params.Branch = $branch
            $params.GitHubToken = $secureGitHubToken  # Keep as SecureString
        }
        else {
            # Get project path if not provided
            if (-not $ProjectPath) {
                $projectPathFunc = Get-Command -Name Get-ProjectPathForDeployment -ErrorAction SilentlyContinue
                if ($projectPathFunc) {
                    $ProjectPath = Get-ProjectPathForDeployment
                    if (-not $ProjectPath) {
                        Write-Host "Project path selection was cancelled or failed. Deployment cannot continue." -ForegroundColor Yellow
                        return $null
                    }
                }
            }
            $params.ProjectPath = $ProjectPath
        }
    }
    else {
        # For auto-detect, always use project path
        if (-not $ProjectPath) {
            $projectPathFunc = Get-Command -Name Get-ProjectPathForDeployment -ErrorAction SilentlyContinue
            if ($projectPathFunc) {
                $ProjectPath = Get-ProjectPathForDeployment
                if (-not $ProjectPath) {
                    Write-Host "Project path selection was cancelled or failed. Deployment cannot continue." -ForegroundColor Yellow
                    return $null
                }
            }
        }
        $params.ProjectPath = $ProjectPath
    }
    
    # Custom domain configuration
    $useCustomDomain = Read-Host "Configure custom domain? (y/n)"
    if ($useCustomDomain -eq "y") {
        $customDomain = Read-Host "Enter domain name (e.g., example.com)"
        $subdomain = Read-Host "Enter subdomain (e.g., www)"
        
        $params.CustomDomain = $customDomain
        $params.Subdomain = $subdomain
    }
    
    return $params
}