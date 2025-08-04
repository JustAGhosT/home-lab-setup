function Deploy-Netlify {
    <#
    .SYNOPSIS
        Deploys a website to Netlify platform.
    
    .DESCRIPTION
        This function deploys a website to Netlify, which is optimized for JAMstack and static sites.
        It supports continuous deployment from Git and form handling.
    
    .PARAMETER AppName
        Application name for the Netlify site.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .PARAMETER Location
        Netlify region for deployment.
    
    .PARAMETER NetlifyToken
        Netlify API token for authentication.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER RepoUrl
        GitHub repository URL for automatic deployments.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .EXAMPLE
        Deploy-Netlify -AppName "my-jamstack-site" -ProjectPath "C:\Projects\my-site" -Location "us-east-1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$Location = "us-east-1",
        
        [Parameter()]
        [string]$NetlifyToken,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main"
    )
    
    Write-Host "=== Deploying to Netlify ===" -ForegroundColor Blue
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Validate project path
    if (-not (Test-Path -Path $ProjectPath)) {
        throw "Project path does not exist: $ProjectPath"
    }
    
    # Step 2: Check for Netlify CLI
    Write-Host "Step 1/5: Checking Netlify CLI installation..." -ForegroundColor Cyan
    $netlifyCli = Get-Command -Name "netlify" -ErrorAction SilentlyContinue
    if (-not $netlifyCli) {
        Write-Host "Netlify CLI not found. Installing..." -ForegroundColor Yellow
        try {
            npm install -g netlify-cli
            Write-Host "Netlify CLI installed successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to install Netlify CLI. Please install it manually: npm install -g netlify-cli"
        }
    }
    else {
        Write-Host "Netlify CLI found." -ForegroundColor Green
    }
    
    # Step 3: Authenticate with Netlify
    Write-Host "Step 2/5: Authenticating with Netlify..." -ForegroundColor Cyan
    if ($NetlifyToken) {
        Write-Host "Using provided Netlify token..." -ForegroundColor White
        $env:NETLIFY_AUTH_TOKEN = $NetlifyToken
    }
    else {
        Write-Host "Please authenticate with Netlify..." -ForegroundColor Yellow
        Write-Host "You will be prompted to log in to your Netlify account." -ForegroundColor White
        try {
            netlify login
            Write-Host "Authentication successful." -ForegroundColor Green
        }
        catch {
            throw "Failed to authenticate with Netlify. Please check your credentials."
        }
    }
    
    # Step 4: Navigate to project directory
    Write-Host "Step 3/5: Preparing project for deployment..." -ForegroundColor Cyan
    Push-Location -Path $ProjectPath
    
    try {
        # Check if project is already linked to Netlify
        $netlifyDir = Test-Path -Path ".netlify"
        
        if ($netlifyDir) {
            Write-Host "Project is already linked to Netlify." -ForegroundColor Green
        }
        else {
            Write-Host "Linking project to Netlify..." -ForegroundColor White
            try {
                netlify link
                Write-Host "Project linked successfully." -ForegroundColor Green
            }
            catch {
                throw "Failed to link project to Netlify: $($_.Exception.Message)"
            }
        }
        
        # Step 5: Deploy to Netlify
        Write-Host "Step 4/5: Deploying to Netlify..." -ForegroundColor Cyan
        Write-Host "This may take a few minutes..." -ForegroundColor White
        
        try {
            # Build the project if needed
            $packageJson = Test-Path -Path "package.json"
            if ($packageJson) {
                Write-Host "Building project..." -ForegroundColor White
                npm run build
            }
            
            # Deploy to Netlify
            $deployOutput = netlify deploy --prod 2>&1
            Write-Host "Deployment output:" -ForegroundColor White
            Write-Host $deployOutput -ForegroundColor Gray
            
            # Extract deployment URL from output
            $deploymentUrl = $deployOutput | Select-String -Pattern "https://.*\.netlify\.app" | ForEach-Object { $_.Matches[0].Value }
            
            if ($deploymentUrl) {
                Write-Host "Step 5/5: Deployment completed successfully!" -ForegroundColor Green
                Write-Host "Deployment URL: $deploymentUrl" -ForegroundColor Green
                
                # Configure custom domain if provided
                if ($CustomDomain) {
                    Write-Host "Configuring custom domain: $CustomDomain" -ForegroundColor Cyan
                    try {
                        netlify domains:add $CustomDomain
                        Write-Host "Custom domain configured successfully." -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Failed to configure custom domain: $($_.Exception.Message)"
                    }
                }
                
                # Return deployment information
                return @{
                    Success       = $true
                    DeploymentUrl = $deploymentUrl
                    AppName       = $AppName
                    Platform      = "Netlify"
                    Region        = $Location
                    CustomDomain  = $CustomDomain
                }
            }
            else {
                throw "Deployment completed but could not extract deployment URL"
            }
        }
        catch {
            throw "Failed to deploy to Netlify: $($_.Exception.Message)"
        }
    }
    finally {
        Pop-Location
    }
} 