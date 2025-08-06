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
        [string]$DeploymentType = "cloudrun",
    
        [Parameter()]
        [ValidateSet("auto", "nodejs", "python", "go", "dotnet", "java", "php", "ruby")]
        [string]$Runtime = "auto",
    
        [Parameter()]
        [switch]$AllowUnauthenticated = $true
    )
    
    Write-Host "=== Deploying to Google Cloud ===" -ForegroundColor Red
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor White
    Write-Host "Runtime: $Runtime" -ForegroundColor White
    Write-Host "Allow Unauthenticated: $AllowUnauthenticated" -ForegroundColor White
    Write-Host ""
    
    # Helper function to detect project type
    function Get-ProjectType {
        param (
            [string]$Path
        )
        
        # Check for Node.js
        if (Test-Path -Path (Join-Path $Path "package.json")) {
            return "nodejs"
        }
        
        # Check for Python
        if ((Test-Path -Path (Join-Path $Path "requirements.txt")) -or 
            (Test-Path -Path (Join-Path $Path "Pipfile")) -or 
            (Test-Path -Path (Join-Path $Path "setup.py")) -or
            (Test-Path -Path (Join-Path $Path "pyproject.toml"))) {
            return "python"
        }
        
        # Check for Go
        if ((Test-Path -Path (Join-Path $Path "go.mod")) -or 
            (Test-Path -Path (Join-Path $Path "main.go"))) {
            return "go"
        }
        
        # Check for .NET
        if ((Get-ChildItem -Path $Path -Filter "*.csproj" -Recurse) -or 
            (Test-Path -Path (Join-Path $Path "Program.cs")) -or 
            (Test-Path -Path (Join-Path $Path "Startup.cs"))) {
            return "dotnet"
        }
        
        # Check for Java
        if ((Test-Path -Path (Join-Path $Path "pom.xml")) -or 
            (Test-Path -Path (Join-Path $Path "build.gradle")) -or
            (Get-ChildItem -Path $Path -Filter "*.java" -Recurse)) {
            return "java"
        }
        
        # Check for PHP
        if ((Test-Path -Path (Join-Path $Path "composer.json")) -or 
            (Get-ChildItem -Path $Path -Filter "*.php" -Recurse)) {
            return "php"
        }
        
        # Check for Ruby
        if ((Test-Path -Path (Join-Path $Path "Gemfile")) -or 
            (Get-ChildItem -Path $Path -Filter "*.rb" -Recurse)) {
            return "ruby"
        }
        
        # Default to Node.js if no clear indicators
        return "nodejs"
    }
    
    # Helper function to generate Dockerfile content based on runtime
    function Get-DockerfileContent {
        param (
            [string]$Runtime,
            [int]$Port = 8080
        )
        
        switch ($Runtime) {
            "nodejs" {
                return @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE $Port
CMD ["npm", "start"]
"@
            }
            "python" {
                return @"
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE $Port
CMD ["python", "app.py"]
"@
            }
            "go" {
                return @"
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main .

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE $Port
CMD ["./main"]
"@
            }
            "dotnet" {
                return @"
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app
COPY *.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app/out .
EXPOSE $Port
CMD ["dotnet", "app.dll"]
"@
            }
            "java" {
                return @"
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE $Port
CMD ["java", "-jar", "app.jar"]
"@
            }
            "php" {
                return @"
FROM php:8.2-apache
WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE $Port
"@
            }
            "ruby" {
                return @"
FROM ruby:3.2-slim
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE $Port
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
"@
            }
            default {
                return @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE $Port
CMD ["npm", "start"]
"@
            }
        }
    }
    
    # Helper function to get App Engine runtime
    function Get-AppEngineRuntime {
        param (
            [string]$Runtime
        )
        
        switch ($Runtime) {
            "nodejs" { return "nodejs18" }
            "python" { return "python311" }
            "go" { return "go119" }
            "java" { return "java17" }
            "php" { return "php82" }
            "ruby" { return "ruby32" }
            default { return "nodejs18" }
        }
    }
    
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
    
    # Detect project type if auto is selected
    $detectedRuntime = if ($Runtime -eq "auto") { Get-ProjectType -Path $ProjectPath } else { $Runtime }
    Write-Host "Detected/Selected Runtime: $detectedRuntime" -ForegroundColor Green
    
    $pushLocationSuccess = $false
    try {
        Push-Location -Path $ProjectPath -ErrorAction Stop
        $pushLocationSuccess = $true
        Write-Host "Successfully navigated to project directory: $ProjectPath" -ForegroundColor Green
    }
    catch {
        throw "Failed to navigate to project directory: $($_.Exception.Message)"
    }
    
    try {
        # Step 6: Deploy based on type
        if ($DeploymentType -eq "cloudrun") {
            Write-Host "Step 5/6: Deploying to Cloud Run..." -ForegroundColor Cyan
            try {
                # Check for Dockerfile
                $dockerfile = Test-Path -Path "Dockerfile"
                if (-not $dockerfile) {
                    Write-Host "Creating Dockerfile for $detectedRuntime runtime..." -ForegroundColor White
                    $dockerfileContent = Get-DockerfileContent -Runtime $detectedRuntime -Port 8080
                    $dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding UTF8
                    Write-Host "Dockerfile created for $detectedRuntime runtime." -ForegroundColor Green
                }
                
                # Build deployment command
                $deployCmd = "gcloud run deploy $AppName --source . --region $Location --format=json"
                if ($AllowUnauthenticated) {
                    $deployCmd += " --allow-unauthenticated"
                }
                
                # Deploy to Cloud Run
                Write-Host "Deploying to Cloud Run..." -ForegroundColor White
                $deployOutput = Invoke-Expression $deployCmd 2>&1
                Write-Host "Deployment output:" -ForegroundColor White
                Write-Host $deployOutput -ForegroundColor Gray
                
                # Parse JSON output to extract service URL
                try {
                    $deployJson = $deployOutput | ConvertFrom-Json
                    $serviceUrl = $deployJson.status.url
                    Write-Host "Service URL extracted from JSON output: $serviceUrl" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to parse JSON output, falling back to regex extraction"
                    $serviceUrl = $deployOutput | Select-String -Pattern "https://.*\.run\.app" | ForEach-Object { $_.Matches[0].Value }
                }
                
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
                    Write-Host "Creating app.yaml for $detectedRuntime runtime..." -ForegroundColor White
                    $appEngineRuntime = Get-AppEngineRuntime -Runtime $detectedRuntime
                    $appYamlContent = @"
runtime: $appEngineRuntime
service: default
env: standard
automatic_scaling:
  target_cpu_utilization: 0.65
  min_instances: 1
  max_instances: 10
"@
                    $appYamlContent | Out-File -FilePath "app.yaml" -Encoding UTF8
                    Write-Host "app.yaml created for $detectedRuntime runtime ($appEngineRuntime)." -ForegroundColor Green
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
        if ($pushLocationSuccess) {
            Pop-Location
            Write-Host "Restored original directory location." -ForegroundColor Green
        }
    }
} 