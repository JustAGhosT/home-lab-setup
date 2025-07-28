<#
.SYNOPSIS
    HomeLab Azure Module
.DESCRIPTION
    Module for HomeLab Azure infrastructure deployment.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
    Version: 1.0.0
#>

$ModulePath = $PSScriptRoot
$ModuleName = (Get-Item $PSScriptRoot).BaseName

# Load dependencies
$requiredModules = @('HomeLab.Utils', 'HomeLab.Logging', 'HomeLab.Core')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module)) {
        $parentPath = Split-Path -Parent $ModulePath
        $siblingPath = Join-Path $parentPath $module
        $manifestPath = Join-Path $siblingPath "$module.psd1"
        if (Test-Path $manifestPath) {
            Import-Module $manifestPath -Force -ErrorAction SilentlyContinue
        } else {
            Import-Module $module -Force -ErrorAction SilentlyContinue
        }
    }
}

# Load private functions
$privatePath = Join-Path $ModulePath 'Private'
if (Test-Path $privatePath) {
    Get-ChildItem "$privatePath\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Load and export public functions
$publicPath = Join-Path $ModulePath 'Public'
$publicFunctions = @()

if (Test-Path $publicPath) {
    Get-ChildItem "$publicPath\*.ps1" -Recurse | ForEach-Object {
        try {
            . $_.FullName
            
            # Extract function name from file
            $content = Get-Content $_.FullName -Raw
            if ($content -match 'function\s+([A-Za-z0-9\-_]+)') {
                $functionName = $matches[1]
                if ($functionName -and $functionName -ne 'returns') {
                    $publicFunctions += $functionName
                }
            }
        } catch {
            Write-Warning "Failed to load function from $($_.Name): $($_.Exception.Message)"
        }
    }
}

# Export public functions
if ($publicFunctions.Count -gt 0) {
    Export-ModuleMember -Function ($publicFunctions | Select-Object -Unique)
}