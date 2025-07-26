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
    
    # Get deployment parameters
    $resourceGroup = Read-Host "Enter resource group name"
    $appName = Read-Host "Enter application name"
    $location = Read-Host "Enter location (default: eastus)"
    if ([string]::IsNullOrWhiteSpace($location)) { $location = "eastus" }
    
    $params = @{
        DeploymentType = $DeploymentType
        ResourceGroup = $resourceGroup
        AppName = $appName
        Location = $location
        SubscriptionId = $Config.SubscriptionId
    }
    
    # Handle GitHub deployment if not auto-detect
    if ($DeploymentType -ne "auto") {
        $useGitHub = Read-Host "Deploy from GitHub? (y/n)"
        if ($useGitHub -eq "y") {
            $repoUrl = Read-Host "Enter GitHub repository URL"
            $branch = Read-Host "Enter branch name (default: main)"
            if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }
            
            # Securely capture GitHub token
            $secureGitHubToken = Read-Host "Enter GitHub personal access token" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureGitHubToken)
            $gitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
            $params.RepoUrl = $repoUrl
            $params.Branch = $branch
            $params.GitHubToken = $gitHubToken
        }
        else {
            # Get project path if not provided
            if (-not $ProjectPath) {
                $projectPathFunc = Get-Command -Name Get-ProjectPathForDeployment -ErrorAction SilentlyContinue
                if ($projectPathFunc) {
                    $ProjectPath = Get-ProjectPathForDeployment
                    if (-not $ProjectPath) {
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