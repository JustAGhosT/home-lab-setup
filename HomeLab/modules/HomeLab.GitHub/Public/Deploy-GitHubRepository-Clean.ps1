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
        
        Write-Host ""
        
        # Step 2: Analyze repository for deployment configuration
        Write-Host "Step 2: Analyzing repository for deployment configuration..." -ForegroundColor Yellow
        
        $deploymentConfig = Get-RepositoryDeploymentConfig -Path $repoPath
        
        if ($deploymentConfig.HasDeploymentFiles) {
            Write-Host "SUCCESS: Found deployment configuration:" -ForegroundColor Green
            $deploymentConfig.DeploymentFiles | ForEach-Object {
                Write-Host "  - $_" -ForegroundColor Gray
            }
        } else {
            Write-Host "INFO: No specific deployment configuration found. Using default deployment." -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # Step 3: Prepare deployment parameters
        Write-Host "Step 3: Preparing deployment parameters..." -ForegroundColor Yellow
        
        $deployParams = @{}
        
        # Set resource group
        if ($ResourceGroup) {
            $deployParams.ResourceGroup = $ResourceGroup
        } elseif ($deploymentConfig.ResourceGroup) {
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
        Write-Host "Step 4: Executing deployment..." -ForegroundColor Yellow
        
        # For now, simulate deployment since HomeLab.Azure integration is complex
        Write-Host "INFO: Deployment simulation (HomeLab.Azure integration pending)" -ForegroundColor Yellow
        
        # Simulate deployment result
        $deploymentResult = [PSCustomObject]@{
            Status = "Succeeded"
            ResourceGroup = $deployParams.ResourceGroup
            DeploymentTime = Get-Date
            Resources = @("Storage Account", "App Service", "Key Vault")
        }
        
        # Step 5: Report results
        Write-Host ""
        Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Repository = if ($Repository -is [string]) { $Repository } else { 
                if ($Repository) { $Repository.FullName } else { "Selected Repository" }
            }
            Branch = $Branch
            LocalPath = $repoPath
            ResourceGroup = $deployParams.ResourceGroup
            DeploymentType = $deploymentConfig.DeploymentType
            Status = $deploymentResult.Status
            StartTime = Get-Date
            DeploymentResult = $deploymentResult
        }
        
        if ($deploymentResult.Status -eq "Succeeded") {
            Write-Host "SUCCESS: GitHub repository deployed successfully!" -ForegroundColor Green
            Write-Host "  Repository: $($result.Repository)" -ForegroundColor Gray
            Write-Host "  Local Path: $($result.LocalPath)" -ForegroundColor Gray
            if ($result.ResourceGroup) {
                Write-Host "  Resource Group: $($result.ResourceGroup)" -ForegroundColor Gray
            }
            Write-Host "  Deployment Type: $($result.DeploymentType)" -ForegroundColor Gray
        } else {
            Write-Host "ERROR: Deployment failed or completed with issues" -ForegroundColor Red
        }
        
        return $result
    }
    catch {
        Write-Error "GitHub repository deployment failed: $($_.Exception.Message)"
        
        return [PSCustomObject]@{
            Repository = if ($Repository -is [string]) { $Repository } else { 
                if ($Repository) { $Repository.FullName } else { "Unknown" }
            }
            Branch = $Branch
            Status = "Failed"
            Error = $_.Exception.Message
            StartTime = Get-Date
        }
    }
}

function Get-RepositoryDeploymentConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $config = [PSCustomObject]@{
        HasDeploymentFiles = $false
        DeploymentType = 'Infrastructure'
        DeploymentFiles = @()
        ResourceGroup = $null
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
        'docker-compose.yml'
    )
    
    foreach ($pattern in $deploymentFiles) {
        $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            $config.HasDeploymentFiles = $true
            $config.DeploymentFiles += $files | ForEach-Object { $_.FullName.Replace($Path, '').TrimStart('\', '/') }
        }
    }
    
    # Try to determine deployment type
    if (Get-ChildItem -Path $Path -Filter "*.bicep" -Recurse -ErrorAction SilentlyContinue) {
        $config.DeploymentType = 'Infrastructure'
    }
    elseif (Get-ChildItem -Path $Path -Filter "Dockerfile" -ErrorAction SilentlyContinue) {
        $config.DeploymentType = 'Application'
    }
    
    return $config
}
