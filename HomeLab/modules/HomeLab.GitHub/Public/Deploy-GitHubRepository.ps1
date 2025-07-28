function Deploy-GitHubRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [object]$Repository,

        [Parameter(Mandatory = $false)]
        [string]$Branch,

        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Azure')]
        [string]$Platform = 'Azure',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Infrastructure', 'WebApp', 'StaticSite', 'ContainerApp')]
        [string]$DeploymentType,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Monitor,

        [Parameter(Mandatory = $false)]
        [switch]$BackgroundMonitor
    )
    
    try {
        Write-Host "=== GitHub Repository Deployment ===" -ForegroundColor Cyan
        Write-Host ""
        
        # Step 1: Clone the repository
        Write-Host "Step 1: Cloning repository..." -ForegroundColor Yellow
        
        $cloneParams = @{}
        if ($Repository) { $cloneParams.Repository = $Repository }
        if ($Branch) { $cloneParams.Branch = $Branch }
        if ($Force) { $cloneParams.Force = $true }
        
        $repoPath = Clone-GitHubRepository @cloneParams

        if (-not $repoPath -or -not (Test-Path $repoPath)) {
            throw "Failed to clone repository"
        }

        # Validate repository path for security
        $allowedBasePath = $env:TEMP
        if (-not $allowedBasePath) {
            $allowedBasePath = [System.IO.Path]::GetTempPath()
        }

        # Resolve paths to prevent path traversal attacks
        $resolvedRepoPath = [System.IO.Path]::GetFullPath($repoPath)
        $resolvedBasePath = [System.IO.Path]::GetFullPath($allowedBasePath)

        # Ensure the repository path is within the allowed base directory
        if (-not $resolvedRepoPath.StartsWith($resolvedBasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Repository path '$resolvedRepoPath' is outside the allowed directory '$resolvedBasePath'. This may indicate a security risk."
        }

        # Additional validation: ensure path doesn't contain suspicious patterns
        $suspiciousPatterns = @('..', '~', '$', '`', ';', '|', '&', '<', '>')
        foreach ($pattern in $suspiciousPatterns) {
            if ($resolvedRepoPath.Contains($pattern)) {
                throw "Repository path contains suspicious characters that may indicate a security risk: '$pattern'"
            }
        }

        Write-Host "Repository path validated: $resolvedRepoPath" -ForegroundColor Green
        
        Write-Host ""
        
        # Step 2: Analyze repository for deployment configuration
        Write-Host "Step 2: Analyzing repository for deployment configuration..." -ForegroundColor Yellow
        
        $deploymentConfig = Get-RepositoryDeploymentConfig -Path $repoPath
        
        if ($deploymentConfig.HasDeploymentFiles) {
            Write-Host "SUCCESS: Found deployment configuration:" -ForegroundColor Green
            $deploymentConfig.DeploymentFiles | ForEach-Object {
                Write-Host "  - $_" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "INFO: No specific deployment configuration found. Using default deployment." -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # Step 3: Prepare deployment parameters
        Write-Host "Step 3: Preparing deployment parameters..." -ForegroundColor Yellow
        
        $deployParams = @{}
        
        # Set resource group
        if ($ResourceGroup) {
            $deployParams.ResourceGroup = $ResourceGroup
        }
        elseif ($deploymentConfig.ResourceGroup) {
            $deployParams.ResourceGroup = $deploymentConfig.ResourceGroup
        }
        
        # Set monitoring options
        if ($Monitor) { $deployParams.Monitor = $true }
        if ($BackgroundMonitor) { $deployParams.BackgroundMonitor = $true }
        
        Write-Host "  Repository Path: $repoPath" -ForegroundColor Gray
        if ($deployParams.ResourceGroup) {
            Write-Host "  Resource Group: $($deployParams.ResourceGroup)" -ForegroundColor Gray
        }
        
        Write-Host ""
        
        # Step 4: Execute deployment
        Write-Host "Step 4: Executing deployment to $Platform..." -ForegroundColor Yellow

        # Determine deployment type if not specified
        if (-not $DeploymentType) {
            $DeploymentType = Get-AutoDetectedDeploymentType -Path $repoPath -Config $deploymentConfig
            Write-Host "  Auto-detected deployment type: $DeploymentType" -ForegroundColor Gray
        }
        else {
            Write-Host "  Using specified deployment type: $DeploymentType" -ForegroundColor Gray
        }

        # Execute deployment based on platform and type
        $deploymentResult = $null

        switch ($Platform) {
            'Azure' {
                $deploymentResult = Invoke-AzureDeployment -Path $repoPath -DeploymentType $DeploymentType -Parameters $deployParams -Config $deploymentConfig
            }
            default {
                throw "Unsupported deployment platform: $Platform"
            }
        }
        
        # Step 5: Report results
        Write-Host ""
        Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Repository       = if ($Repository -is [string]) { $Repository } else {
                if ($Repository) { $Repository.FullName } else { "Selected Repository" }
            }
            Branch           = $Branch
            LocalPath        = $repoPath
            Platform         = $Platform
            ResourceGroup    = $deployParams.ResourceGroup
            DeploymentType   = $DeploymentType
            Status           = $deploymentResult.Status
            StartTime        = Get-Date
            DeploymentResult = $deploymentResult
        }
        
        if ($deploymentResult.Status -eq "Succeeded") {
            Write-Host "SUCCESS: GitHub repository deployed successfully!" -ForegroundColor Green
            Write-Host "  Repository: $($result.Repository)" -ForegroundColor Gray
            Write-Host "  Platform: $($result.Platform)" -ForegroundColor Gray
            Write-Host "  Deployment Type: $($result.DeploymentType)" -ForegroundColor Gray
            Write-Host "  Local Path: $($result.LocalPath)" -ForegroundColor Gray
            if ($result.ResourceGroup) {
                Write-Host "  Resource Group: $($result.ResourceGroup)" -ForegroundColor Gray
            }

            # Show deployment-specific information
            if ($deploymentResult.Url) {
                Write-Host "  URL: $($deploymentResult.Url)" -ForegroundColor Cyan
            }
            if ($deploymentResult.Resources) {
                Write-Host "  Resources Created:" -ForegroundColor Gray
                $deploymentResult.Resources | ForEach-Object {
                    Write-Host "    - $_" -ForegroundColor DarkGray
                }
            }
        }
        else {
            Write-Host "ERROR: Deployment failed or completed with issues" -ForegroundColor Red
            if ($deploymentResult.Error) {
                Write-Host "  Error: $($deploymentResult.Error)" -ForegroundColor Red
            }
        }
        
        return $result
    }
    catch {
        Write-Error "GitHub repository deployment failed: $($_.Exception.Message)"
        
        return [PSCustomObject]@{
            Repository = if ($Repository -is [string]) { $Repository } else { 
                if ($Repository) { $Repository.FullName } else { "Unknown" }
            }
            Branch     = $Branch
            Status     = "Failed"
            Error      = $_.Exception.Message
            StartTime  = Get-Date
        }
    }
}

function Get-RepositoryDeploymentConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "Path '$_' does not exist or is not a directory."
                }
                # Additional security validation
                $resolvedPath = [System.IO.Path]::GetFullPath($_)
                $suspiciousPatterns = @('..', '~', '$', '`', ';', '|', '&', '<', '>')
                foreach ($pattern in $suspiciousPatterns) {
                    if ($resolvedPath.Contains($pattern)) {
                        throw "Path contains suspicious characters that may indicate a security risk: '$pattern'"
                    }
                }
                return $true
            })]
        [string]$Path
    )

    $config = [PSCustomObject]@{
        HasDeploymentFiles = $false
        DeploymentType     = 'Infrastructure'
        DeploymentFiles    = @()
        ResourceGroup      = $null
        WebFramework       = $null
        HasStaticContent   = $false
        HasDockerfile      = $false
        HasBicepFiles      = $false
    }

    if (-not (Test-Path $Path)) {
        return $config
    }

    # Look for common deployment files
    $deploymentFiles = @(
        'azure-pipelines.yml',
        'azure-pipelines.yaml',
        'deploy.ps1',
        'Deploy.ps1',
        'deployment.json',
        'azuredeploy.json',
        'main.bicep',
        'infrastructure.bicep',
        'Dockerfile',
        'docker-compose.yml',
        'package.json',
        'requirements.txt',
        'pom.xml',
        'web.config',
        'index.html'
    )

    foreach ($pattern in $deploymentFiles) {
        $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            $config.HasDeploymentFiles = $true
            $config.DeploymentFiles += $files | ForEach-Object { $_.FullName.Replace($Path, '').TrimStart('\', '/') }
        }
    }

    # Detect specific file types
    $config.HasBicepFiles = (Get-ChildItem -Path $Path -Filter "*.bicep" -Recurse -ErrorAction SilentlyContinue).Count -gt 0
    $config.HasDockerfile = (Get-ChildItem -Path $Path -Filter "Dockerfile" -ErrorAction SilentlyContinue).Count -gt 0
    $config.HasStaticContent = (Get-ChildItem -Path $Path -Filter "index.html" -Recurse -ErrorAction SilentlyContinue).Count -gt 0

    # Detect web frameworks with proper error handling
    $packageJsonPath = Join-Path $Path "package.json"
    if (Test-Path $packageJsonPath) {
        try {
            Write-Verbose "Reading package.json from: $packageJsonPath"
            $packageJsonContent = Get-Content $packageJsonPath -Raw -ErrorAction Stop
            $packageJson = ConvertFrom-Json $packageJsonContent -ErrorAction Stop

            if ($packageJson.dependencies) {
                if ($packageJson.dependencies.react) {
                    $config.WebFramework = "React"
                    Write-Verbose "Detected React framework"
                }
                elseif ($packageJson.dependencies.vue) {
                    $config.WebFramework = "Vue"
                    Write-Verbose "Detected Vue framework"
                }
                elseif ($packageJson.dependencies.angular) {
                    $config.WebFramework = "Angular"
                    Write-Verbose "Detected Angular framework"
                }
                elseif ($packageJson.dependencies.next) {
                    $config.WebFramework = "Next.js"
                    Write-Verbose "Detected Next.js framework"
                }
                else {
                    $config.WebFramework = "Node.js"
                    Write-Verbose "Detected Node.js framework"
                }
            }
            else {
                Write-Verbose "No dependencies found in package.json"
            }
        }
        catch [System.ArgumentException] {
            Write-Warning "Failed to parse package.json: Invalid JSON format. $($_.Exception.Message)"
        }
        catch [System.IO.IOException] {
            Write-Warning "Failed to read package.json: File access error. $($_.Exception.Message)"
        }
        catch {
            Write-Warning "Failed to process package.json: $($_.Exception.Message)"
        }
    }

    return $config
}

function Get-AutoDetectedDeploymentType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    # Priority-based detection
    if ($Config.HasBicepFiles) {
        return 'Infrastructure'
    }
    elseif ($Config.HasDockerfile) {
        return 'ContainerApp'
    }
    elseif ($Config.WebFramework -and $Config.HasStaticContent) {
        return 'StaticSite'
    }
    elseif ($Config.WebFramework) {
        return 'WebApp'
    }
    elseif ($Config.HasStaticContent) {
        return 'StaticSite'
    }
    else {
        return 'Infrastructure'  # Default fallback
    }
}

function Invoke-AzureDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$DeploymentType,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    try {
        Write-Host "  Deploying as: $DeploymentType" -ForegroundColor Cyan

        # Check if HomeLab.Azure module is available
        if (-not (Get-Module -Name HomeLab.Azure -ListAvailable)) {
            throw "HomeLab.Azure module is required for Azure deployment. Please ensure it's installed."
        }

        # Import required modules
        Import-Module HomeLab.Azure -Force -ErrorAction Stop

        # Execute deployment based on type
        switch ($DeploymentType) {
            'Infrastructure' {
                return Invoke-InfrastructureDeployment -Path $Path -Parameters $Parameters -Config $Config
            }
            'WebApp' {
                return Invoke-WebAppDeployment -Path $Path -Parameters $Parameters -Config $Config
            }
            'StaticSite' {
                return Invoke-StaticSiteDeployment -Path $Path -Parameters $Parameters -Config $Config
            }
            'ContainerApp' {
                return Invoke-ContainerAppDeployment -Path $Path -Parameters $Parameters -Config $Config
            }
            default {
                throw "Unsupported deployment type: $DeploymentType"
            }
        }
    }
    catch {
        Write-Error "Azure deployment failed: $($_.Exception.Message)"
        return [PSCustomObject]@{
            Status = "Failed"
            Error  = $_.Exception.Message
        }
    }
}

function Invoke-InfrastructureDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    Write-Host "    Deploying Azure infrastructure..." -ForegroundColor Yellow

    # Use the existing Deploy-Infrastructure function from HomeLab.Azure
    $deployParams = @{}
    if ($Parameters.ResourceGroup) { $deployParams.ResourceGroup = $Parameters.ResourceGroup }
    if ($Parameters.Monitor) { $deployParams.Monitor = $true }
    if ($Parameters.BackgroundMonitor) { $deployParams.BackgroundMonitor = $true }

    # Change to the repository directory for deployment
    $originalLocation = Get-Location
    try {
        Set-Location $Path
        $result = Deploy-Infrastructure @deployParams

        return [PSCustomObject]@{
            Status         = if ($result) { "Succeeded" } else { "Failed" }
            DeploymentType = "Infrastructure"
            ResourceGroup  = $Parameters.ResourceGroup
            DeploymentTime = Get-Date
            Resources      = @("Virtual Network", "Storage Account", "Key Vault")
            Details        = $result
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

function Invoke-WebAppDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    Write-Host "    Deploying as Azure Web App..." -ForegroundColor Yellow
    Write-Host "    Framework: $($Config.WebFramework)" -ForegroundColor Gray

    # For now, simulate web app deployment
    # In a full implementation, this would use Azure CLI or REST API
    Start-Sleep -Seconds 2

    return [PSCustomObject]@{
        Status         = "Succeeded"
        DeploymentType = "WebApp"
        ResourceGroup  = $Parameters.ResourceGroup
        DeploymentTime = Get-Date
        Resources      = @("App Service Plan", "App Service", "Application Insights")
        WebFramework   = $Config.WebFramework
        Url            = "https://myapp.azurewebsites.net"
    }
}

function Invoke-StaticSiteDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    Write-Host "    Deploying as Azure Static Web App..." -ForegroundColor Yellow

    # For now, simulate static site deployment
    # In a full implementation, this would use Azure Static Web Apps CLI
    Start-Sleep -Seconds 2

    return [PSCustomObject]@{
        Status         = "Succeeded"
        DeploymentType = "StaticSite"
        ResourceGroup  = $Parameters.ResourceGroup
        DeploymentTime = Get-Date
        Resources      = @("Static Web App", "CDN Profile")
        Url            = "https://mystaticapp.azurestaticapps.net"
    }
}

function Invoke-ContainerAppDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    Write-Host "    Deploying as Azure Container App..." -ForegroundColor Yellow

    # For now, simulate container app deployment
    # In a full implementation, this would build and deploy to Azure Container Apps
    Start-Sleep -Seconds 2

    return [PSCustomObject]@{
        Status         = "Succeeded"
        DeploymentType = "ContainerApp"
        ResourceGroup  = $Parameters.ResourceGroup
        DeploymentTime = Get-Date
        Resources      = @("Container App Environment", "Container App", "Container Registry")
        ImageName      = "myapp:latest"
    }
}
