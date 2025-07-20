# Script to update Pester to the latest version

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator to install modules globally."
    Write-Host "Continuing with current user scope..."
}

# Check current Pester version
$currentVersion = (Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1).Version
Write-Host "Current Pester version: $currentVersion"

# Install or update Pester
try {
    Write-Host "Installing/updating Pester module..."
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser -MinimumVersion 5.0
    Write-Host "Pester module updated successfully." -ForegroundColor Green
} 
catch {
    Write-Error "Failed to install Pester module: $_"
    exit 1
}

# Verify the installation
$newVersion = (Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1).Version
Write-Host "New Pester version: $newVersion"

# Import the updated module
Import-Module Pester -MinimumVersion 5.0 -Force

Write-Host "`nPester has been updated. You can now run tests with the latest version." -ForegroundColor Green
Write-Host "Run tests with: .\Run-Tests.ps1 -TestType Unit"