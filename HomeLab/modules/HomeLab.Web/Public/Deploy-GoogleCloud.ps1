function Deploy-GoogleCloud {
    <#
    .SYNOPSIS
        Deploys a website to Google Cloud using Cloud Run or App Engine.
    
    .DESCRIPTION
        This function deploys a website to Google Cloud using Cloud Run for serverless containers
        or App Engine for platform-as-a-service deployments.
    
    .PARAMETER AppName
        Application name for the Google Cloud resources.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .PARAMETER Location
        Google Cloud region for deployment.
    
    .PARAMETER GcpProject
        Google Cloud project ID.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER RepoUrl
        GitHub repository URL for automatic deployments.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .PARAMETER DeploymentType
        Type of deployment (cloudrun|appengine). Default is cloudrun.
    
    .EXAMPLE
        Deploy-GoogleCloud -AppName "my-app" -ProjectPath "C:\Projects\my-app" -Location "us-central1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$Location = "us-central1",
        
        [Parameter()]
        [string]$GcpProject,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [ValidateSet("cloudrun", "appengine")]
        [string]$DeploymentType = "cloudrun"
    )
    
    Write-Host "=== Deploying to Google Cloud ===" -ForegroundColor Red
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Validate project path
    if (-not (Test-Path -Path $ProjectPath)) {
        throw "Project path does not exist: $ProjectPath"
    }
    
    # Step 2: Check for Google Cloud CLI
    Write-Host "Step 1/6: Checking Google Cloud CLI installation..." -ForegroundColor Cyan
    $gcloudCli = Get-Command -Name "gcloud" -ErrorAction SilentlyContinue
    if (-not $gcloudCli) {
        Write-Host "Google Cloud CLI not found. Please install Google Cloud CLI first:" -ForegroundColor Yellow
        Write-Host "https://cloud.google.com/sdk/docs/install" -ForegroundColor Cyan
        throw "Google Cloud CLI is required for deployment. Please install it and configure your credentials."
    }
    else {
        Write-Host "Google Cloud CLI found." -ForegroundColor Green
    }
    
    # Step 3: Check Google Cloud authentication
    Write-Host "Step 2/6: Checking Google Cloud authentication..." -ForegroundColor Cyan
    try {
        $gcloudAuth = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gcloudAuth)) {
            Write-Host "Google Cloud authentication required. Please run 'gcloud auth login' first." -ForegroundColor Yellow
            throw "Google Cloud authentication required"
        }
        Write-Host "Google Cloud authentication verified: $gcloudAuth" -ForegroundColor Green
    }
    catch {
        throw "Failed to verify Google Cloud authentication: $($_.Exception.Message)"
    }
    
    # Step 4: Set project
    Write-Host "Step 3/6: Setting Google Cloud project..." -ForegroundColor Cyan
    if ($GcpProject) {
        try {
            gcloud config set project $GcpProject
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to set Google Cloud project"
            }
            Write-Host "Google Cloud project set to: $GcpProject" -ForegroundColor Green
        }
        catch {
            throw "Failed to set Google Cloud project: $($_.Exception.Message)"
        }
    }
    else {
        $currentProject = gcloud config get-value project 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "No Google Cloud project configured. Please set a project ID."
        }
        Write-Host "Using current Google Cloud project: $currentProject" -ForegroundColor Green
    }
    
    # Step 5: Navigate to project directory
    Write-Host "Step 4/6: Preparing project for deployment..." -ForegroundColor Cyan
    Push-Location -Path $ProjectPath
    
    try {
        # Step 6: Deploy based on type
        if ($DeploymentType -eq "cloudrun") {
            Write-Host "Step 5/6: Deploying to Cloud Run..." -ForegroundColor Cyan
            try {
                # Check for Dockerfile
                $dockerfile = Test-Path -Path "Dockerfile"
                if (-not $dockerfile) {
                    Write-Host "Creating Dockerfile for Cloud Run..." -ForegroundColor White
                    # Create a basic Dockerfile for Node.js
                    $dockerfileContent = @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 8080
CMD ["npm", "start"]
"@
                    $dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding UTF8
                    Write-Host "Dockerfile created." -ForegroundColor Green
                }
                
                # Deploy to Cloud Run
                Write-Host "Deploying to Cloud Run..." -ForegroundColor White
                $deployOutput = gcloud run deploy $AppName --source . --region $Location --allow-unauthenticated 2>&1
                Write-Host "Deployment output:" -ForegroundColor White
                Write-Host $deployOutput -ForegroundColor Gray
                
                # Extract service URL
                $serviceUrl = $deployOutput | Select-String -Pattern "https://.*\.run\.app" | ForEach-Object { $_.Matches[0].Value }
                
                if ($serviceUrl) {
                    Write-Host "Step 6/6: Cloud Run deployment completed successfully!" -ForegroundColor Green
                    Write-Host "Service URL: $serviceUrl" -ForegroundColor Green
                    
                    # Return deployment information
                    return @{
                        Success       = $true
                        DeploymentUrl = $serviceUrl
                        AppName       = $AppName
                        Platform      = "Google Cloud"
                        Service       = "Cloud Run"
                        Region        = $Location
                        CustomDomain  = $CustomDomain
                    }
                }
                else {
                    throw "Deployment completed but could not extract service URL"
                }
            }
            catch {
                throw "Failed to deploy to Cloud Run: $($_.Exception.Message)"
            }
        }
        else {
            # App Engine deployment
            Write-Host "Step 5/6: Deploying to App Engine..." -ForegroundColor Cyan
            try {
                # Check for app.yaml
                $appYaml = Test-Path -Path "app.yaml"
                if (-not $appYaml) {
                    Write-Host "Creating app.yaml for App Engine..." -ForegroundColor White
                    # Create a basic app.yaml for Node.js
                    $appYamlContent = @"
runtime: nodejs18
service: default
env: standard
automatic_scaling:
  target_cpu_utilization: 0.65
  min_instances: 1
  max_instances: 10
"@
                    $appYamlContent | Out-File -FilePath "app.yaml" -Encoding UTF8
                    Write-Host "app.yaml created." -ForegroundColor Green
                }
                
                # Deploy to App Engine
                Write-Host "Deploying to App Engine..." -ForegroundColor White
                $deployOutput = gcloud app deploy --quiet 2>&1
                Write-Host "Deployment output:" -ForegroundColor White
                Write-Host $deployOutput -ForegroundColor Gray
                
                # Get App Engine URL
                $appUrl = gcloud app browse --no-launch-browser 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Step 6/6: App Engine deployment completed successfully!" -ForegroundColor Green
                    Write-Host "App URL: $appUrl" -ForegroundColor Green
                    
                    # Return deployment information
                    return @{
                        Success       = $true
                        DeploymentUrl = $appUrl
                        AppName       = $AppName
                        Platform      = "Google Cloud"
                        Service       = "App Engine"
                        Region        = $Location
                        CustomDomain  = $CustomDomain
                    }
                }
                else {
                    throw "Failed to get App Engine URL"
                }
            }
            catch {
                throw "Failed to deploy to App Engine: $($_.Exception.Message)"
            }
        }
    }
    finally {
        Pop-Location
    }
} 