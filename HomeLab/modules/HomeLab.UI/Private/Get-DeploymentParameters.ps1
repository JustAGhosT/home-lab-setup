function Get-DeploymentParameters {
    <#
    .SYNOPSIS
        Gets common deployment parameters for website deployments.
    
    .DESCRIPTION
        This function collects common deployment parameters such as resource group, app name,
        location, GitHub deployment options, and custom domain configuration with progress indicators.
    
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
        [ValidateSet("static", "appservice", "auto", "vercel", "netlify", "aws", "gcp")]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    # Import progress bar functions using cross-platform path construction
    $progressBarPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Public\ProgressBar"
    . (Join-Path -Path $progressBarPath -ChildPath "Show-ProgressBar.ps1")
    . (Join-Path -Path $progressBarPath -ChildPath "Update-ProgressBar.ps1")
    . (Join-Path -Path $PSScriptRoot -ChildPath "Helpers.ps1")
    
    # Helper function to check and import Azure module
    function Test-AzureModuleAvailability {
        if (-not (Get-Module -Name Az -ListAvailable)) {
            Write-Host "Azure PowerShell module (Az) is not installed or not available." -ForegroundColor Red
            Write-Host "Please install the Az module using: Install-Module -Name Az -AllowClobber -Force" -ForegroundColor Yellow
            Write-Host "Or import it using: Import-Module Az" -ForegroundColor Yellow
            return $false
        }
        
        # Import Az module if not already loaded
        if (-not (Get-Module -Name Az)) {
            try {
                Import-Module Az -ErrorAction Stop
                return $true
            }
            catch {
                Write-Host "Failed to import Azure PowerShell module: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        return $true
    }
    
    # Calculate total steps for progress tracking
    $totalSteps = 7  # Basic parameters + Cloud Platform + GitHub/Project + Custom domain
    if ($DeploymentType -eq "auto") {
        $totalSteps = 6  # No GitHub option for auto-detect
    }
    
    $currentStep = 0
    
    Write-Host "`n=== Collecting Deployment Parameters ===" -ForegroundColor Cyan
    Write-Host "Following naming convention: [env]-[regionabbreviation]-[typeabbreviation]-project" -ForegroundColor Yellow
    Write-Host ""
    
    # Step 1: Cloud Platform Selection
    $currentStep++
    Show-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Activity "Step $currentStep/$totalSteps" -Status "Selecting cloud platform..." -ForegroundColor Cyan
    
    Write-Host "`nCloud Platform Selection:" -ForegroundColor Yellow
    Write-Host "Choose your deployment platform:" -ForegroundColor White
    Write-Host "1. Azure (Static Web Apps / App Service)" -ForegroundColor Cyan
    Write-Host "2. Vercel (Next.js, React, Vue optimized)" -ForegroundColor Green
    Write-Host "3. Netlify (Static sites, JAMstack)" -ForegroundColor Blue
    Write-Host "4. AWS (S3 + CloudFront, Amplify)" -ForegroundColor Yellow
    Write-Host "5. Google Cloud (Cloud Run, App Engine)" -ForegroundColor Red
    Write-Host "6. Auto-detect best platform" -ForegroundColor Magenta
    
    do {
        $platformChoice = Read-Host "Enter platform choice (1-6)"
        if ($platformChoice -match '^\d+$' -and [int]$platformChoice -ge 1 -and [int]$platformChoice -le 6) {
            switch ([int]$platformChoice) {
                1 { $cloudPlatform = "azure"; $platformName = "Azure" }
                2 { $cloudPlatform = "vercel"; $platformName = "Vercel" }
                3 { $cloudPlatform = "netlify"; $platformName = "Netlify" }
                4 { $cloudPlatform = "aws"; $platformName = "AWS" }
                5 { $cloudPlatform = "gcp"; $platformName = "Google Cloud" }
                6 { $cloudPlatform = "auto"; $platformName = "Auto-detect" }
            }
            break
        }
        Write-Host "Invalid choice. Please enter a number between 1 and 6." -ForegroundColor Red
    } while ($true)
    
    Write-Host "Selected platform: $platformName" -ForegroundColor Green
    
    # Step 2: Environment Selection
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Selecting environment..." -Activity "Step $currentStep/$totalSteps"
    
    $environments = @("dev", "test", "staging", "prod")
    Write-Host "`nSelect environment:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $environments.Count; $i++) {
        Write-Host "$($i + 1). $($environments[$i])" -ForegroundColor White
    }
    
    do {
        $envChoice = Read-Host "Enter environment choice (1-$($environments.Count))"
        if ($envChoice -match '^\d+$' -and [int]$envChoice -ge 1 -and [int]$envChoice -le $environments.Count) {
            $environment = $environments[[int]$envChoice - 1]
            break
        }
        Write-Host "Invalid choice. Please enter a number between 1 and $($environments.Count)." -ForegroundColor Red
    } while ($true)
    
    # Step 2: Resource Group Selection
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Selecting resource group..." -Activity "Step $currentStep/$totalSteps"
    
    Write-Host "`nResource Group Selection:" -ForegroundColor Yellow
    Write-Host "Current resource groups in subscription:" -ForegroundColor White
    
    # Check if Az module is available before calling Azure cmdlets
    if (Test-AzureModuleAvailability) {
        try {
            $existingRGs = Get-AzResourceGroup -ErrorAction SilentlyContinue | Sort-Object Name
            if ($existingRGs) {
                for ($i = 0; $i -lt $existingRGs.Count; $i++) {
                    Write-Host "$($i + 1). $($existingRGs[$i].Name) - $($existingRGs[$i].Location)" -ForegroundColor White
                }
            }
            Write-Host "N. Create New Resource Group" -ForegroundColor Green
        }
        catch {
            Write-Host "Unable to retrieve existing resource groups. You can create a new one." -ForegroundColor Yellow
            Write-Host "N. Create New Resource Group" -ForegroundColor Green
        }
    }
    else {
        Write-Host "N. Create New Resource Group" -ForegroundColor Green
    }
    
    do {
        $rgChoice = Read-Host "Select resource group number or N for new"
        if ($rgChoice -eq "N" -or $rgChoice -eq "n") {
            # Create new resource group
            do {
                $resourceGroup = Read-Host "Enter new resource group name (following convention: $environment-[region]-[type]-project)"
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
            break
        }
        elseif ($rgChoice -match '^\d+$' -and [int]$rgChoice -ge 1 -and [int]$rgChoice -le $existingRGs.Count) {
            $resourceGroup = $existingRGs[[int]$rgChoice - 1].Name
            break
        }
        else {
            Write-Host "Invalid choice. Please enter a valid number or 'N'." -ForegroundColor Red
        }
    } while ($true)
    
    # Step 3: Application Name
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Configuring application name..." -Activity "Step $currentStep/$totalSteps"
    
    Write-Host "`nApplication Name Configuration:" -ForegroundColor Yellow
    Write-Host "Following naming convention: $environment-[region]-[type]-project" -ForegroundColor White
    
    # Get platform-specific locations
    $validLocations = switch ($cloudPlatform) {
        "azure" {
            @(
                @{Name = "eastus"; Abbreviation = "eus" }, @{Name = "eastus2"; Abbreviation = "eus2" }, 
                @{Name = "southcentralus"; Abbreviation = "scus" }, @{Name = "westus2"; Abbreviation = "wus2" }, 
                @{Name = "westus3"; Abbreviation = "wus3" }, @{Name = "australiaeast"; Abbreviation = "aue" }, 
                @{Name = "southeastasia"; Abbreviation = "sea" }, @{Name = "northeurope"; Abbreviation = "neu" }, 
                @{Name = "swedencentral"; Abbreviation = "swe" }, @{Name = "uksouth"; Abbreviation = "uks" }, 
                @{Name = "westeurope"; Abbreviation = "weu" }, @{Name = "centralus"; Abbreviation = "cus" }, 
                @{Name = "southafricanorth"; Abbreviation = "zan" }, @{Name = "centralindia"; Abbreviation = "cin" }, 
                @{Name = "eastasia"; Abbreviation = "eas" }, @{Name = "japaneast"; Abbreviation = "jpe" }, 
                @{Name = "koreacentral"; Abbreviation = "krc" }, @{Name = "canadacentral"; Abbreviation = "cac" }, 
                @{Name = "francecentral"; Abbreviation = "frc" }, @{Name = "germanywestcentral"; Abbreviation = "gwc" }, 
                @{Name = "norwayeast"; Abbreviation = "noe" }, @{Name = "switzerlandnorth"; Abbreviation = "chn" }, 
                @{Name = "uaenorth"; Abbreviation = "uan" }, @{Name = "brazilsouth"; Abbreviation = "brs" }
            )
        }
        "vercel" {
            @(
                @{Name = "us-east-1"; Abbreviation = "use1" }, @{Name = "us-west-1"; Abbreviation = "usw1" },
                @{Name = "eu-west-1"; Abbreviation = "euw1" }, @{Name = "ap-southeast-1"; Abbreviation = "apse1" },
                @{Name = "auto"; Abbreviation = "auto" }
            )
        }
        "netlify" {
            @(
                @{Name = "us-east-1"; Abbreviation = "use1" }, @{Name = "us-west-1"; Abbreviation = "usw1" },
                @{Name = "eu-west-1"; Abbreviation = "euw1" }, @{Name = "ap-southeast-1"; Abbreviation = "apse1" },
                @{Name = "auto"; Abbreviation = "auto" }
            )
        }
        "aws" {
            @(
                @{Name = "us-east-1"; Abbreviation = "use1" }, @{Name = "us-west-2"; Abbreviation = "usw2" },
                @{Name = "eu-west-1"; Abbreviation = "euw1" }, @{Name = "ap-southeast-1"; Abbreviation = "apse1" },
                @{Name = "ap-northeast-1"; Abbreviation = "apne1" }, @{Name = "sa-east-1"; Abbreviation = "sae1" }
            )
        }
        "gcp" {
            @(
                @{Name = "us-central1"; Abbreviation = "usc1" }, @{Name = "us-east1"; Abbreviation = "use1" },
                @{Name = "europe-west1"; Abbreviation = "euw1" }, @{Name = "asia-southeast1"; Abbreviation = "apse1" },
                @{Name = "asia-northeast1"; Abbreviation = "apne1" }, @{Name = "southamerica-east1"; Abbreviation = "sae1" }
            )
        }
        default {
            @(
                @{Name = "us-east-1"; Abbreviation = "use1" }, @{Name = "us-west-1"; Abbreviation = "usw1" },
                @{Name = "eu-west-1"; Abbreviation = "euw1" }, @{Name = "ap-southeast-1"; Abbreviation = "apse1" }
            )
        }
    }
    
    Write-Host "`nSelect location:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $validLocations.Count; $i++) {
        $loc = $validLocations[$i]
        Write-Host "$($i + 1). $($loc.Name) ($($loc.Abbreviation))" -ForegroundColor White
    }
    
    do {
        $locationChoice = Read-Host "Enter location choice (1-$($validLocations.Count))"
        if ($locationChoice -match '^\d+$' -and [int]$locationChoice -ge 1 -and [int]$locationChoice -le $validLocations.Count) {
            $selectedLocation = $validLocations[[int]$locationChoice - 1]
            $location = $selectedLocation.Name
            $locationAbbr = $selectedLocation.Abbreviation
            break
        }
        Write-Host "Invalid choice. Please enter a number between 1 and $($validLocations.Count)." -ForegroundColor Red
    } while ($true)
    
    # Determine type abbreviation based on deployment type and platform
    $typeAbbr = switch ($cloudPlatform) {
        "azure" {
            switch ($DeploymentType) {
                "static" { "swa" }
                "appservice" { "app" }
                "auto" { "auto" }
                default { "web" }
            }
        }
        "vercel" { "ver" }
        "netlify" { "net" }
        "aws" { "aws" }
        "gcp" { "gcp" }
        default { "web" }
    }
    
    # Suggest app name based on convention
    $suggestedAppName = "$environment-$locationAbbr-$typeAbbr-project"
    Write-Host "`nSuggested app name: $suggestedAppName" -ForegroundColor Green
    
    do {
        $appName = Read-Host "Enter application name (or press Enter for suggested)"
        if ([string]::IsNullOrWhiteSpace($appName)) {
            $appName = $suggestedAppName
        }
        
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
    
    $params = @{
        DeploymentType = $DeploymentType
        ResourceGroup  = $resourceGroup
        AppName        = $appName
        Location       = $location
        SubscriptionId = $Config.SubscriptionId
    }
    
    # Step 4: GitHub/Project Configuration
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Configuring deployment source..." -Activity "Step $currentStep/$totalSteps"
    
    # Handle GitHub deployment if not auto-detect
    if ($DeploymentType -ne "auto") {
        Write-Host "`nDeployment Source Configuration:" -ForegroundColor Yellow
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
        Write-Host "`nProject Path Configuration (Required for Auto-Detection):" -ForegroundColor Yellow
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
    
    # Step 5: Custom Domain Configuration
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Configuring custom domain..." -Activity "Step $currentStep/$totalSteps"
    
    Write-Host "`nCustom Domain Configuration:" -ForegroundColor Yellow
    $useCustomDomain = Read-Host "Configure custom domain? (y/n)"
    if ($useCustomDomain -eq "y") {
        $customDomain = Read-Host "Enter domain name (e.g., example.com)"
        $subdomain = Read-Host "Enter subdomain (e.g., www)"
        
        $params.CustomDomain = $customDomain
        $params.Subdomain = $subdomain
    }
    
    # Step 6: Platform-Specific Configuration
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Configuring platform-specific settings..." -Activity "Step $currentStep/$totalSteps"
    
    Write-Host "`nPlatform-Specific Configuration:" -ForegroundColor Yellow
    Write-Host "Configuring settings for $platformName..." -ForegroundColor White
    
    # Platform-specific configuration
    switch ($cloudPlatform) {
        "vercel" {
            Write-Host "Vercel Configuration:" -ForegroundColor Green
            $vercelToken = Read-Host "Enter Vercel API token (optional - will prompt during deployment if not provided)" -AsSecureString
            if ($vercelToken -and $vercelToken.Length -gt 0) {
                $params.VercelToken = $vercelToken
            }
            $params.Platform = "vercel"
        }
        "netlify" {
            Write-Host "Netlify Configuration:" -ForegroundColor Blue
            $netlifyToken = Read-Host "Enter Netlify API token (optional - will prompt during deployment if not provided)" -AsSecureString
            if ($netlifyToken -and $netlifyToken.Length -gt 0) {
                $params.NetlifyToken = $netlifyToken
            }
            $params.Platform = "netlify"
        }
        "aws" {
            Write-Host "AWS Configuration:" -ForegroundColor Yellow
            $awsRegion = Read-Host "Enter AWS region (default: us-east-1)"
            if ([string]::IsNullOrWhiteSpace($awsRegion)) { $awsRegion = "us-east-1" }
            $params.AwsRegion = $awsRegion
            $params.Platform = "aws"
        }
        "gcp" {
            Write-Host "Google Cloud Configuration:" -ForegroundColor Red
            $gcpProject = Read-Host "Enter Google Cloud project ID (optional - will prompt during deployment if not provided)"
            if (-not [string]::IsNullOrWhiteSpace($gcpProject)) {
                $params.GcpProject = $gcpProject
            }
            $params.Platform = "gcp"
        }
        default {
            $params.Platform = $cloudPlatform
        }
    }
    
    # Final step: Show summary
    $currentStep++
    Update-ProgressBar -PercentComplete (($currentStep / $totalSteps) * 100) -Status "Configuration complete!" -Activity "Step $currentStep/$totalSteps"
    
    Write-Host "`n=== Deployment Configuration Summary ===" -ForegroundColor Green
    Write-Host "Platform: $platformName" -ForegroundColor White
    Write-Host "Environment: $environment" -ForegroundColor White
    Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
    Write-Host "Application Name: $appName" -ForegroundColor White
    Write-Host "Location: $location" -ForegroundColor White
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor White
    
    if ($params.RepoUrl) {
        Write-Host "GitHub Repository: $($params.RepoUrl)" -ForegroundColor White
        Write-Host "Branch: $($params.Branch)" -ForegroundColor White
    }
    elseif ($params.ProjectPath) {
        Write-Host "Project Path: $($params.ProjectPath)" -ForegroundColor White
    }
    
    if ($params.CustomDomain) {
        Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
    }
    
    Write-Host "`nConfiguration follows naming convention: $environment-$locationAbbr-$typeAbbr-project" -ForegroundColor Green
    
    return $params
}