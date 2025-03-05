<#
.SYNOPSIS
    HomeLab.Security Module
.DESCRIPTION
    Provides security functionality for HomeLab, including:
      - VPN Certificate Management (e.g. New-VpnRootCertificate, New-VpnClientCertificate, Add-AdditionalClientCertificate, Add-VpnGatewayCertificate)
      - VPN Client Management (e.g. VpnAddComputer, VpnConnectDisconnect, Get-VpnConnectionStatus)
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

# Dot-source all private function files.
Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        . $_.FullName
        Write-Verbose "Imported private function file: $($_.FullName)"
    }
    catch {
        Write-Error "Failed to import private function file $($_.FullName): $_"
    }
}

# Export public functions. Using '*' in the manifest exports everything dot-sourced in the Public folder.
# If you need to fine-tune this list, you can specify the function names.
Export-ModuleMember -Function $publicPath.BaseName
