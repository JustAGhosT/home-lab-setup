<#
.SYNOPSIS
    HomeLab.Azure Module
.DESCRIPTION
    Provides Azure infrastructure deployment functionality for HomeLab,
    including deploying full or component-based infrastructure and enabling/disabling NAT Gateways.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Define paths for Public and Private function files.
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath "Private"

# Dot-source all public function files.
Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        . $_.FullName
        Write-Verbose "Imported public function file: $($_.FullName)"
    }
    catch {
        Write-Error "Failed to import public function file $($_.FullName): $_"
    }
}

# Dot-source all private function files (if needed).
Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        . $_.FullName
        Write-Verbose "Imported private function file: $($_.FullName)"
    }
    catch {
        Write-Error "Failed to import private function file $($_.FullName): $_"
    }
}

# Export public functions.
# (Using '*' here since our manifest lists all public functions for export.)
Export-ModuleMember -Function $publicPath.BaseName
