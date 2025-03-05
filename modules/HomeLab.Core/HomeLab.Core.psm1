<#
.SYNOPSIS
    HomeLab Core Module
.DESCRIPTION
    Provides core functionality for HomeLab including configuration management,
    logging, and prerequisite testing. This module aggregates functions such as:
      - Get-Configuration
      - Initialize-HomeLab
      - Install-Prerequisites
      - Reset-Configuration
      - Set-Configuration
      - Test-Prerequisites
      - Test-SetupComplete
      - Update-ConfigurationParameter
      - Write-Log
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Dot-source all public functions from the Public folder.
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
Get-ChildItem -Path $publicPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Optionally, dot-source Private functions if needed:
#$privatePath = Join-Path -Path $PSScriptRoot -ChildPath "Private"
#Get-ChildItem -Path $privatePath -Filter "*.ps1" | ForEach-Object {
#    . $_.FullName
#}

# Export key functions for module consumers.
Export-ModuleMember -Function `
    Get-Configuration, `
    Initialize-HomeLab, `
    Install-Prerequisites, `
    Reset-Configuration, `
    Set-Configuration, `
    Test-Prerequisites, `
    Test-SetupComplete, `
    Update-ConfigurationParameter, `
    Write-Log
