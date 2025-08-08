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
            $npmOutput = npm install -g vercel 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Vercel CLI installed successfully." -ForegroundColor Green
            }
            else {
                throw "npm install failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            $errorDetails = $_.Exception.Message
            $npmError = if ($npmOutput) { $npmOutput | Select-Object -Last 5 } else { "No additional error details available" }
            
            Write-Error "Failed to install Vercel CLI: $errorDetails"
            Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
            Write-Host "1. Check your internet connection" -ForegroundColor White
            Write-Host "2. Verify you have sufficient permissions (try running as administrator)" -ForegroundColor White
            Write-Host "3. Check if npm is properly installed: npm --version" -ForegroundColor White
            Write-Host "4. Try clearing npm cache: npm cache clean --force" -ForegroundColor White
            Write-Host "5. Install manually: npm install -g vercel" -ForegroundColor White
            
            if ($npmError) {
                Write-Host "`nLast npm output:" -ForegroundColor Red
                Write-Host $npmError -ForegroundColor Gray
            }
            
            throw "Vercel CLI installation failed. Please resolve the issues above and try again."
        }
    }
    else {
        Write-Host "Vercel CLI found." -ForegroundColor Green
    }
    
    # Step 3: Authenticate with Vercel
    Write-Host "Step 2/5: Authenticating with Vercel..." -ForegroundColor Cyan
    $tokenWasSet = $false
    
    if ($VercelToken) {
        Write-Host "Using provided Vercel token..." -ForegroundColor White
        # Store token temporarily for this session only
        $env:VERCEL_TOKEN = $VercelToken
        $tokenWasSet = $true
        Write-Host "Token set for this deployment session." -ForegroundColor Green
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
            
            # Extract deployment URL from output with comprehensive regex pattern
            $deploymentUrl = $null
            
            # Comprehensive regex pattern for Vercel URLs
            $vercelUrlPatterns = @(
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app",           # Standard Vercel app URLs
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app/",          # With trailing slash
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app\s",         # With whitespace
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app$",          # End of line
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app[^\w\-_/]",  # With non-alphanumeric delimiter
                "https?://[a-zA-Z0-9\-_]+\.vercel\.app\b"          # Word boundary
            )
            
            foreach ($pattern in $vercelUrlPatterns) {
                $match = $deployOutput | Select-String -Pattern $pattern | Select-Object -First 1
                if ($match) {
                    $deploymentUrl = $match.Matches[0].Value.Trim()
                    Write-Host "Deployment URL extracted using pattern: $pattern" -ForegroundColor Green
                    break
                }
            }
            
            # Fallback: Look for any URL-like pattern in the output
            if (-not $deploymentUrl) {
                $fallbackPattern = "https?://[^\s]+\.vercel\.app[^\s]*"
                $fallbackMatch = $deployOutput | Select-String -Pattern $fallbackPattern | Select-Object -First 1
                if ($fallbackMatch) {
                    $deploymentUrl = $fallbackMatch.Matches[0].Value.Trim()
                    Write-Host "Deployment URL extracted using fallback pattern" -ForegroundColor Yellow
                }
            }
            
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
                Write-Error "Deployment completed but could not extract deployment URL from output"
                Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
                Write-Host "1. Check the deployment output above for any error messages" -ForegroundColor White
                Write-Host "2. Verify the deployment was successful in your Vercel dashboard" -ForegroundColor White
                Write-Host "3. Try running 'vercel ls' to see your recent deployments" -ForegroundColor White
                Write-Host "4. Check if the deployment URL format has changed" -ForegroundColor White
                
                Write-Host "`nDeployment output for debugging:" -ForegroundColor Cyan
                Write-Host $deployOutput -ForegroundColor Gray
                
                throw "Failed to extract deployment URL. Please check the Vercel dashboard for the deployment status."
            }
        }
        catch {
            Write-Error "Failed to deploy to Vercel: $($_.Exception.Message)"
            Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
            Write-Host "1. Check your Vercel authentication: vercel whoami" -ForegroundColor White
            Write-Host "2. Verify your project is properly linked: vercel link" -ForegroundColor White
            Write-Host "3. Check for any build errors in the output above" -ForegroundColor White
            Write-Host "4. Ensure your project has the necessary configuration files" -ForegroundColor White
            
            throw "Vercel deployment failed. Please resolve the issues above and try again."
        }
    }
    finally {
        # Clean up sensitive token data
        if ($tokenWasSet) {
            Write-Host "Cleaning up sensitive token data..." -ForegroundColor Cyan
            Remove-Item Env:VERCEL_TOKEN -ErrorAction SilentlyContinue
            $env:VERCEL_TOKEN = $null
            Write-Host "Token data cleared from environment." -ForegroundColor Green
        }
        
        # Restore original directory
        Pop-Location
        Write-Host "Restored original directory location." -ForegroundColor Green
    }
} 