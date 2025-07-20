# Test script for HomeLab.Web module
# This script tests the website deployment functionality

function Test-WebDeployment {
    [CmdletBinding()]
    param()

    # Import required modules
    Import-Module HomeLab.Core
    Import-Module HomeLab.Azure
    Import-Module HomeLab.Web

    Write-Host "Starting HomeLab.Web deployment tests..." -ForegroundColor Cyan

    # Test 1: Test module loading
    Write-Host "Test 1: Verifying module functions..." -ForegroundColor Yellow
    $requiredFunctions = @(
        "Deploy-Website",
        "Add-GitHubWorkflows",
        "Show-DeploymentTypeInfo",
        "Select-ProjectFolder"
    )

    $missingFunctions = @()
    foreach ($function in $requiredFunctions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            $missingFunctions += $function
        }
    }

    if ($missingFunctions.Count -gt 0) {
        Write-Host "❌ Failed: Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "✅ Passed: All required functions are available" -ForegroundColor Green
    }

    # Test 2: Test deployment type detection
    Write-Host "`nTest 2: Testing deployment type detection..." -ForegroundColor Yellow
    
    # Create temporary test directories
    $testDir = Join-Path -Path $env:TEMP -ChildPath "HomeLab-WebTest-$(Get-Random)"
    $staticDir = Join-Path -Path $testDir -ChildPath "static-test"
    $appServiceDir = Join-Path -Path $testDir -ChildPath "appservice-test"
    
    # Create test directories
    New-Item -Path $staticDir -ItemType Directory -Force | Out-Null
    New-Item -Path $appServiceDir -ItemType Directory -Force | Out-Null
    
    # Create static website test files
    Set-Content -Path "$staticDir\index.html" -Value "<html><body>Test</body></html>"
    
    # Create app service test files
    $packageJson = @"
{
  "name": "test-app",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.17.1"
  }
}
"@
    Set-Content -Path "$appServiceDir\package.json" -Value $packageJson
    Set-Content -Path "$appServiceDir\server.js" -Value "const express = require('express');"
    
    # Test static website detection
    try {
        $staticType = Get-DeploymentType -Path $staticDir
        if ($staticType -eq "static") {
            Write-Host "✅ Passed: Correctly detected static website" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed: Did not correctly detect static website" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed: Error testing static website detection: $_" -ForegroundColor Red
    }
    
    # Test app service detection
    try {
        $appServiceType = Get-DeploymentType -Path $appServiceDir
        if ($appServiceType -eq "appservice") {
            Write-Host "✅ Passed: Correctly detected app service" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed: Did not correctly detect app service" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed: Error testing app service detection: $_" -ForegroundColor Red
    }
    
    # Test 3: Test GitHub workflow generation
    Write-Host "`nTest 3: Testing GitHub workflow generation..." -ForegroundColor Yellow
    try {
        Add-GitHubWorkflows -ProjectPath $staticDir -DeploymentType "static" -CustomDomain "example.com"
        
        $workflowFiles = @(
            ".github\workflows\deploy-azure.yml",
            ".github\workflows\deploy-multi-env.yml",
            "DEPLOYMENT-GUIDE.md"
        )
        
        $missingFiles = @()
        foreach ($file in $workflowFiles) {
            $filePath = Join-Path -Path $staticDir -ChildPath $file
            if (-not (Test-Path -Path $filePath)) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -gt 0) {
            Write-Host "❌ Failed: Missing workflow files: $($missingFiles -join ', ')" -ForegroundColor Red
        } else {
            Write-Host "✅ Passed: All workflow files were created" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed: Error testing GitHub workflow generation: $_" -ForegroundColor Red
    }
    
    # Test 4: Test Azure connectivity
    Write-Host "`nTest 4: Testing Azure connectivity..." -ForegroundColor Yellow
    try {
        $context = Get-AzContext -ErrorAction Stop
        if ($context) {
            Write-Host "✅ Passed: Successfully connected to Azure" -ForegroundColor Green
            Write-Host "  Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed: Not connected to Azure" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Failed: Error testing Azure connectivity: $_" -ForegroundColor Red
        Write-Host "  Run Connect-AzAccount to connect to Azure before deployment" -ForegroundColor Yellow
    }
    
    # Clean up test directories
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "`nHomeLab.Web deployment tests completed" -ForegroundColor Cyan
}

# Run the tests
Test-WebDeployment