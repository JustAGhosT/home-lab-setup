function Deploy-Vercel {
    <#
    .SYNOPSIS
        Deploys a website to Vercel platform.
    
    .DESCRIPTION
        This function deploys a website to Vercel, which is optimized for Next.js, React, Vue, and other modern frameworks.
        It supports automatic framework detection and zero-config deployments.
    
    .PARAMETER AppName
        Application name for the Vercel project.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .PARAMETER Location
        Vercel region for deployment.
    
    .PARAMETER VercelToken
        Vercel API token for authentication.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER RepoUrl
        GitHub repository URL for automatic deployments.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .EXAMPLE
        Deploy-Vercel -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-app" -Location "us-east-1"
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
        [string]$VercelToken,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main"
    )
    
    Write-Host "=== Deploying to Vercel ===" -ForegroundColor Green
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Validate project path
    if (-not (Test-Path -Path $ProjectPath)) {
        throw "Project path does not exist: $ProjectPath"
    }
    
    # Step 2: Check for Vercel CLI
    Write-Host "Step 1/5: Checking Vercel CLI installation..." -ForegroundColor Cyan
    $vercelCli = Get-Command -Name "vercel" -ErrorAction SilentlyContinue
    if (-not $vercelCli) {
        Write-Host "Vercel CLI not found. Installing..." -ForegroundColor Yellow
        try {
            npm install -g vercel
            Write-Host "Vercel CLI installed successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to install Vercel CLI. Please install it manually: npm install -g vercel"
        }
    }
    else {
        Write-Host "Vercel CLI found." -ForegroundColor Green
    }
    
    # Step 3: Authenticate with Vercel
    Write-Host "Step 2/5: Authenticating with Vercel..." -ForegroundColor Cyan
    if ($VercelToken) {
        Write-Host "Using provided Vercel token..." -ForegroundColor White
        $env:VERCEL_TOKEN = $VercelToken
    }
    else {
        Write-Host "Please authenticate with Vercel..." -ForegroundColor Yellow
        Write-Host "You will be prompted to log in to your Vercel account." -ForegroundColor White
        try {
            vercel login
            Write-Host "Authentication successful." -ForegroundColor Green
        }
        catch {
            throw "Failed to authenticate with Vercel. Please check your credentials."
        }
    }
    
    # Step 4: Navigate to project directory
    Write-Host "Step 3/5: Preparing project for deployment..." -ForegroundColor Cyan
    Push-Location -Path $ProjectPath
    
    try {
        # Check if project is already linked to Vercel
        $vercelJson = Test-Path -Path "vercel.json"
        $vercelDir = Test-Path -Path ".vercel"
        
        if ($vercelDir) {
            Write-Host "Project is already linked to Vercel." -ForegroundColor Green
        }
        else {
            Write-Host "Linking project to Vercel..." -ForegroundColor White
            try {
                vercel link --yes
                Write-Host "Project linked successfully." -ForegroundColor Green
            }
            catch {
                throw "Failed to link project to Vercel: $($_.Exception.Message)"
            }
        }
        
        # Step 5: Deploy to Vercel
        Write-Host "Step 4/5: Deploying to Vercel..." -ForegroundColor Cyan
        Write-Host "This may take a few minutes..." -ForegroundColor White
        
        $deployArgs = @("--prod")
        
        if ($Location -and $Location -ne "auto") {
            $deployArgs += "--regions", $Location
        }
        
        try {
            $deployOutput = vercel deploy @deployArgs 2>&1
            Write-Host "Deployment output:" -ForegroundColor White
            Write-Host $deployOutput -ForegroundColor Gray
            
            # Extract deployment URL from output
            $deploymentUrl = $deployOutput | Select-String -Pattern "https://.*\.vercel\.app" | ForEach-Object { $_.Matches[0].Value }
            
            if ($deploymentUrl) {
                Write-Host "Step 5/5: Deployment completed successfully!" -ForegroundColor Green
                Write-Host "Deployment URL: $deploymentUrl" -ForegroundColor Green
                
                # Configure custom domain if provided
                if ($CustomDomain) {
                    Write-Host "Configuring custom domain: $CustomDomain" -ForegroundColor Cyan
                    try {
                        vercel domains add $CustomDomain
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
                    Platform      = "Vercel"
                    Region        = $Location
                    CustomDomain  = $CustomDomain
                }
            }
            else {
                throw "Deployment completed but could not extract deployment URL"
            }
        }
        catch {
            throw "Failed to deploy to Vercel: $($_.Exception.Message)"
        }
    }
    finally {
        Pop-Location
    }
} 