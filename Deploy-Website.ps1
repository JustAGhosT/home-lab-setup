<#
.SYNOPSIS
    Multi-platform website deployment utility using HomeLab
.DESCRIPTION
    This script provides a streamlined entry point for deploying websites to multiple
    cloud platforms including Azure, Vercel, Netlify, AWS, and Google Cloud using
    the HomeLab environment. It automatically imports the necessary modules and
    starts the website deployment process with minimal setup.
.NOTES
    Author: Jurie Smit
    Version: 2.0.0
    Date: March 2025
.EXAMPLE
    # Basic usage - will prompt for all required information
    .\Deploy-Website.ps1
.EXAMPLE
    # Deploy to Azure with parameters
    .\Deploy-Website.ps1 -Platform "Azure" -DeploymentType static -ResourceGroup "rg-portfolio" -AppName "portfolio-prod" -SubscriptionId "abc123"
.EXAMPLE
    # Deploy to Vercel with parameters
    .\Deploy-Website.ps1 -Platform "Vercel" -AppName "my-nextjs-app" -ProjectPath "C:\Projects\my-app" -Location "us-east-1"
.EXAMPLE
    # Deploy to Netlify with parameters
    .\Deploy-Website.ps1 -Platform "Netlify" -AppName "my-jamstack-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1"
.EXAMPLE
    # Deploy to AWS with parameters
    .\Deploy-Website.ps1 -Platform "AWS" -AppName "my-static-site" -ProjectPath "C:\Projects\my-app" -Location "us-east-1"
.EXAMPLE
    # Deploy to Google Cloud with parameters
    .\Deploy-Website.ps1 -Platform "GoogleCloud" -AppName "my-app" -ProjectPath "C:\Projects\my-app" -Location "us-central1"
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("Azure", "Vercel", "Netlify", "AWS", "GoogleCloud", "Auto")]
    [string]$Platform = "Auto",
    
    [Parameter()]
    [ValidateSet("static", "appservice", "auto")]
    [string]$DeploymentType,
    
    [Parameter()]
    [string]$Subdomain,
    
    [Parameter()]
    [string]$ResourceGroup,
    
    [Parameter()]
    [string]$Location,
    
    [Parameter()]
    [string]$AppName,
    
    [Parameter()]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$CustomDomain,
    
    [Parameter()]
    [string]$RepoUrl,
    
    [Parameter()]
    [string]$Branch = "main",
    
    [Parameter()]
    [string]$ProjectPath,
    
    [Parameter()]
    [switch]$ShowHelp
)

# Show help if requested
if ($ShowHelp) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    return
}

# Function to get platform-specific default location
function Get-PlatformDefaultLocation {
    param([string]$Platform)
    
    switch ($Platform) {
        "Azure" { return "westeurope" }
        "Vercel" { return "us-east-1" }
        "Netlify" { return "us-east-1" }
        "AWS" { return "us-east-1" }
        "GoogleCloud" { return "us-central1" }
        default { return "us-east-1" }
    }
}

# Function to check and install the Az PowerShell module if needed (Azure only)
function Ensure-AzModule {
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Host "The Az PowerShell module is required for Azure deployments but not installed." -ForegroundColor Yellow
        $installPrompt = Read-Host "Would you like to install it now? (y/n)"
        
        if ($installPrompt -eq "y") {
            Write-Host "Installing Az PowerShell module. This may take a few minutes..." -ForegroundColor Cyan
            Install-Module -Name Az -AllowClobber -Force
            return $true
        }
        else {
            Write-Host "Az module installation declined. Cannot proceed with Azure deployment without the Az module." -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# Function to check if user is logged in to Azure (Azure only)
function Ensure-AzureLogin {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "You are not logged in to Azure. Initiating login process..." -ForegroundColor Yellow
            Connect-AzAccount
            return $?  # Return success/failure of Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Host "You are not logged in to Azure. Initiating login process..." -ForegroundColor Yellow
        Connect-AzAccount
        return $?  # Return success/failure of Connect-AzAccount
    }
}

# Function to import the HomeLab module
function Import-HomeLabModule {
    try {
        # Try to import the HomeLab module
        $moduleBasePath = Join-Path -Path $PSScriptRoot -ChildPath "HomeLab"
        $modulePath = Join-Path -Path $moduleBasePath -ChildPath "HomeLab.psd1"
        
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            Write-Host "HomeLab module imported successfully." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "HomeLab module not found at expected path: $modulePath" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error importing HomeLab module: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to get GitHub repositories for the authenticated user
function Get-GitHubRepositories {
    param(
        [System.Security.SecureString]$GitHubToken
    )
    
    try {
        # Convert SecureString to plain text temporarily
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken)
        $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        try {
            $headers = @{
                'Authorization' = "token $plainToken"
                'Accept'        = 'application/vnd.github.v3+json'
            }
            
            $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers -Method Get
            
            # Clear plain text from memory immediately
            $plainToken = $null
            [System.GC]::Collect()
            
            return $response | Where-Object { -not $_.private -or $_.private -eq $false } | Sort-Object -Property 'updated_at' -Descending
        }
        finally {
            # Ensure plain text is cleared even if an error occurs
            if ($plainToken) {
                $plainToken = $null
                [System.GC]::Collect()
            }
        }
    }
    catch {
        Write-Host "Error fetching GitHub repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to securely get GitHub token
function Get-GitHubToken {
    Write-Host "GitHub Personal Access Token (optional, for private repos):" -ForegroundColor Cyan
    Write-Host "Leave empty if not needed or if using public repositories." -ForegroundColor Gray
    
    $token = Read-Host -AsSecureString -Prompt "GitHub Token"
    
    if ($token.Length -gt 0) {
        return $token
    }
    return $null
}

# Function to display platform-specific welcome message
function Show-PlatformWelcome {
    param([string]$Platform)
    
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                        HomeLab Website Deployment                           ║" -ForegroundColor Cyan  
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    switch ($Platform) {
        "Azure" {
            Write-Host "This utility will help you deploy websites to Azure using either:" -ForegroundColor White
            Write-Host "  • Azure Static Web Apps (for static sites, SPAs)" -ForegroundColor Green
            Write-Host "  • Azure App Service (for dynamic web applications)" -ForegroundColor Green
        }
        "Vercel" {
            Write-Host "This utility will help you deploy websites to Vercel:" -ForegroundColor White
            Write-Host "  • Optimized for Next.js, React, Vue, Angular" -ForegroundColor Green
            Write-Host "  • Automatic framework detection and edge functions" -ForegroundColor Green
        }
        "Netlify" {
            Write-Host "This utility will help you deploy websites to Netlify:" -ForegroundColor White
            Write-Host "  • JAMstack optimized platform" -ForegroundColor Green
            Write-Host "  • Form handling and serverless functions" -ForegroundColor Green
        }
        "AWS" {
            Write-Host "This utility will help you deploy websites to AWS:" -ForegroundColor White
            Write-Host "  • S3 + CloudFront for static hosting" -ForegroundColor Green
            Write-Host "  • Cost-effective and scalable solution" -ForegroundColor Green
        }
        "GoogleCloud" {
            Write-Host "This utility will help you deploy websites to Google Cloud:" -ForegroundColor White
            Write-Host "  • Cloud Run for serverless containers" -ForegroundColor Green
            Write-Host "  • App Engine for platform-as-a-service" -ForegroundColor Green
        }
        "Auto" {
            Write-Host "This utility will help you deploy websites to multiple platforms:" -ForegroundColor White
            Write-Host "  • Azure (Static Web Apps & App Service)" -ForegroundColor Green
            Write-Host "  • Vercel (Next.js, React, Vue optimized)" -ForegroundColor Green
            Write-Host "  • Netlify (JAMstack platform)" -ForegroundColor Green
            Write-Host "  • AWS (S3 + CloudFront)" -ForegroundColor Green
            Write-Host "  • Google Cloud (Cloud Run & App Engine)" -ForegroundColor Green
        }
    }
    Write-Host ""
}

# Function to get platform-specific deployment URL
function Get-PlatformDeploymentUrl {
    param(
        [string]$Platform,
        [string]$AppName,
        [hashtable]$DeploymentResult
    )
    
    switch ($Platform) {
        "Azure" {
            if ($DeploymentResult.DeploymentType -eq "static") {
                return "https://$AppName.azurestaticapps.net"
            }
            else {
                return "https://$AppName.azurewebsites.net"
            }
        }
        "Vercel" {
            return "https://$AppName.vercel.app"
        }
        "Netlify" {
            return "https://$AppName.netlify.app"
        }
        "AWS" {
            return "https://$AppName.s3-website-$($DeploymentResult.Region).amazonaws.com"
        }
        "GoogleCloud" {
            if ($DeploymentResult.DeploymentType -eq "cloudrun") {
                return "https://$AppName-$($DeploymentResult.Hash).run.app"
            }
            else {
                return "https://$AppName.appspot.com"
            }
        }
        default {
            return $DeploymentResult.DeploymentUrl
        }
    }
}

# Main script execution
Clear-Host

# Determine platform if Auto is selected
if ($Platform -eq "Auto") {
    Write-Host "Platform Selection:" -ForegroundColor Cyan
    Write-Host "1. Azure (Static Web Apps & App Service)" -ForegroundColor White
    Write-Host "2. Vercel (Next.js, React, Vue optimized)" -ForegroundColor White
    Write-Host "3. Netlify (JAMstack platform)" -ForegroundColor White
    Write-Host "4. AWS (S3 + CloudFront)" -ForegroundColor White
    Write-Host "5. Google Cloud (Cloud Run & App Engine)" -ForegroundColor White
    
    do {
        $platformChoice = Read-Host "Select platform (1-5)"
    } while ($platformChoice -notin @("1", "2", "3", "4", "5"))
    
    switch ($platformChoice) {
        "1" { $Platform = "Azure" }
        "2" { $Platform = "Vercel" }
        "3" { $Platform = "Netlify" }
        "4" { $Platform = "AWS" }
        "5" { $Platform = "GoogleCloud" }
    }
}

# Set default location if not provided
if (-not $Location) {
    $Location = Get-PlatformDefaultLocation -Platform $Platform
}

# Show platform-specific welcome message
Show-PlatformWelcome -Platform $Platform

# Platform-specific prerequisite checks
if ($Platform -eq "Azure") {
    Write-Host "Checking Azure prerequisites..." -ForegroundColor Yellow
    if (-not (Ensure-AzModule)) {
        Write-Host "❌ Az PowerShell module is required but not available." -ForegroundColor Red
        Write-Host "   Please install it and run this script again." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✅ Az PowerShell module is available" -ForegroundColor Green
    
    if (-not (Ensure-AzureLogin)) {
        Write-Host "❌ Azure login failed. Cannot proceed with Azure deployment." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✅ Azure authentication successful" -ForegroundColor Green
}
else {
    Write-Host "Checking general prerequisites..." -ForegroundColor Yellow
    Write-Host "✅ Platform-specific checks will be performed during deployment" -ForegroundColor Green
}

# Import HomeLab module
if (-not (Import-HomeLabModule)) {
    Write-Host "❌ Failed to import HomeLab module. Cannot proceed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Collect deployment parameters
$deployParams = @{
    Platform = $Platform
}

if ($DeploymentType) { $deployParams.DeploymentType = $DeploymentType }
if ($ResourceGroup) { $deployParams.ResourceGroup = $ResourceGroup }
if ($AppName) { $deployParams.AppName = $AppName }
if ($SubscriptionId) { $deployParams.SubscriptionId = $SubscriptionId }
if ($Location) { $deployParams.Location = $Location }
if ($CustomDomain) { $deployParams.CustomDomain = $CustomDomain }
if ($Subdomain) { $deployParams.Subdomain = $Subdomain }
if ($RepoUrl) { $deployParams.RepoUrl = $RepoUrl }
if ($Branch) { $deployParams.Branch = $Branch }
if ($ProjectPath) { $deployParams.ProjectPath = $ProjectPath }

# Execute deployment based on platform
try {
    Write-Host "Starting deployment to $Platform..." -ForegroundColor Green
    
    switch ($Platform) {
        "Azure" {
            Deploy-Azure @deployParams
        }
        "Vercel" {
            Deploy-Vercel @deployParams
        }
        "Netlify" {
            Deploy-Netlify @deployParams
        }
        "AWS" {
            Deploy-AWS @deployParams
        }
        "GoogleCloud" {
            Deploy-GoogleCloud @deployParams
        }
    }
    
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "You can now access your website at:" -ForegroundColor Cyan
    
    # Generate appropriate URL based on platform
    $deploymentUrl = Get-PlatformDeploymentUrl -Platform $Platform -AppName $AppName -DeploymentResult $deployParams
    
    if ($CustomDomain -and $Subdomain) {
        Write-Host "https://$Subdomain.$CustomDomain" -ForegroundColor White
    }
    else {
        Write-Host $deploymentUrl -ForegroundColor White
    }
}
catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "For more details, see HomeLab logs." -ForegroundColor Yellow
    exit 1
}