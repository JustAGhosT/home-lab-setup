<#
.SYNOPSIS
    HomeLab.Security Module
.DESCRIPTION
    Provides security functionality for HomeLab, including VPN certificate and client management.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Define paths for Public and Private function files
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath "Private"

# Dot-source all public function files
Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        . $_.FullName
        Write-Verbose "Imported public function file: $($_.FullName)"
    }
    catch {
        Write-Error "Failed to import public function file $($_.FullName): $_"
    }
}

# Dot-source all private function files
Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        . $_.FullName
        Write-Verbose "Imported private function file: $($_.FullName)"
    }
    catch {
        Write-Error "Failed to import private function file $($_.FullName): $_"
    }
}

# No need to export functions here - they should be listed in the module manifest
