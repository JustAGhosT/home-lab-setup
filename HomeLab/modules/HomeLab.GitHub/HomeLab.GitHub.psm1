#Requires -Version 5.1

<#
.SYNOPSIS
    HomeLab.GitHub PowerShell Module

.DESCRIPTION
    This module provides GitHub integration functionality for the HomeLab deployment system.
    It includes functions for GitHub authentication, repository management, and deployment integration.

.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Created: 2025-07-28
#>

# Get the module root path
$ModuleRoot = $PSScriptRoot

Write-Verbose "Starting HomeLab.GitHub module initialization from $ModuleRoot"

# Load private functions first (internal helper functions)
$PrivatePath = Join-Path -Path $ModuleRoot -ChildPath 'Private'
$PrivateFunctionCount = 0

if (Test-Path -Path $PrivatePath) {
    $PrivateFunctions = Get-ChildItem -Path "$PrivatePath\*.ps1" -ErrorAction SilentlyContinue
    
    Write-Host "Loading private functions from $PrivatePath..." -ForegroundColor Cyan
    Write-Verbose "Found $($PrivateFunctions.Count) private function files"
    
    foreach ($Function in $PrivateFunctions) {
        try {
            . $Function.FullName
            $PrivateFunctionCount++
            Write-Verbose "Loaded private function: $($Function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import private function $($Function.BaseName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "  SUCCESS: Loaded $PrivateFunctionCount private functions" -ForegroundColor Green
}
else {
    Write-Warning "Private directory not found: $PrivatePath"
}

# Load public functions (to be exported)
$PublicPath = Join-Path -Path $ModuleRoot -ChildPath 'Public'
$PublicFunctionCount = 0

if (Test-Path -Path $PublicPath) {
    $PublicFunctions = Get-ChildItem -Path "$PublicPath\*.ps1" -ErrorAction SilentlyContinue
    
    Write-Host "Loading public functions from $PublicPath..." -ForegroundColor Cyan
    Write-Verbose "Found $($PublicFunctions.Count) public function files"
    
    foreach ($Function in $PublicFunctions) {
        try {
            . $Function.FullName
            $PublicFunctionCount++
            Write-Verbose "Loaded public function: $($Function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import public function $($Function.BaseName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "  SUCCESS: Loaded $PublicFunctionCount public functions" -ForegroundColor Green
}
else {
    Write-Warning "Public directory not found: $PublicPath"
}

# Initialize module variables
$script:GitHubApiBaseUrl = "https://api.github.com"
$script:GitHubCredentialTarget = "HomeLab.GitHub.Token"

Write-Host "HomeLab.GitHub module loaded successfully" -ForegroundColor Green
Write-Verbose "Exported $PublicFunctionCount public functions"

# Export module members (functions are exported via the manifest)
Export-ModuleMember -Function * -Variable GitHubApiBaseUrl, GitHubCredentialTarget
