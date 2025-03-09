<#
.SYNOPSIS
    HomeLab Azure Module
.DESCRIPTION
    Module for HomeLab Azure infrastructure deployment with proper dependency handling.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
    Version: 1.0.4
#>

#region Initialization
# Save original preferences to restore later
$originalVerbosePreference = $VerbosePreference
$originalErrorActionPreference = $ErrorActionPreference
$originalWarningPreference = $WarningPreference

# Set preferences for module loading
$VerbosePreference = 'Continue'  # Show verbose output during loading
$ErrorActionPreference = 'Continue'  # Don't terminate on errors
$WarningPreference = 'Continue'  # Show all warnings

# Get module path for reference
$ModulePath = $PSScriptRoot
$ModuleName = (Get-Item $PSScriptRoot).BaseName

Write-Verbose "Starting $ModuleName module initialization from $ModulePath"
#endregion

#region Dependency Management
# Define required modules
$requiredModules = @('HomeLab.Utils', 'HomeLab.Logging', 'HomeLab.Core')
$missingModules = @()
$loadedModules = @()

Write-Host "Checking dependencies for $ModuleName..." -ForegroundColor Cyan

foreach ($module in $requiredModules) {
    Write-Host "Checking module: $module" -ForegroundColor Yellow
    
    # Check if module is already loaded
    if (Get-Module -Name $module) {
        Write-Host "  ✓ Module $module is already loaded" -ForegroundColor Green
        $loadedModules += $module
        continue
    }
    
    $moduleLoaded = $false
    
    # Try to load from relative path first (sibling directory)
    $siblingPath = Join-Path -Path (Split-Path -Parent $ModulePath) -ChildPath $module -AdditionalChildPath "$module.psd1"
    
    if (Test-Path -Path $siblingPath) {
        Write-Host "  → Found $module at $siblingPath" -ForegroundColor Yellow
        try {
            Import-Module -Name $siblingPath -Force -ErrorAction Stop
            Write-Host "  ✓ Successfully loaded $module from sibling path" -ForegroundColor Green
            $moduleLoaded = $true
            $loadedModules += $module
        }
        catch {
            Write-Warning "  ✗ Failed to load $module from sibling path: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "  → Module not found at sibling path, checking PSModulePath" -ForegroundColor Yellow
    }
    
    # If not loaded from sibling path, try PSModulePath
    if (-not $moduleLoaded) {
        try {
            Import-Module -Name $module -Force -ErrorAction Stop
            Write-Host "  ✓ Successfully loaded $module from PSModulePath" -ForegroundColor Green
            $moduleLoaded = $true
            $loadedModules += $module
        }
        catch {
            Write-Warning "  ✗ Failed to load $module from PSModulePath: $($_.Exception.Message)"
        }
    }
    
    # If module couldn't be loaded, add to missing modules list
    if (-not $moduleLoaded) {
        $missingModules += $module
    }
}

# Display summary of dependency check
Write-Host "Dependency check summary:" -ForegroundColor Cyan
Write-Host "  - Total required modules: $($requiredModules.Count)" -ForegroundColor Cyan
Write-Host "  - Successfully loaded: $($loadedModules.Count)" -ForegroundColor $(if ($loadedModules.Count -eq $requiredModules.Count) { 'Green' } else { 'Yellow' })
Write-Host "  - Missing modules: $($missingModules.Count)" -ForegroundColor $(if ($missingModules.Count -eq 0) { 'Green' } else { 'Red' })

if ($missingModules.Count -gt 0) {
    Write-Warning "Missing required modules: $($missingModules -join ', '). Some functionality may be limited."
}
#endregion

#region Function Loading
# Load private functions (internal to the module)
$privatePath = Join-Path -Path $ModulePath -ChildPath 'Private'
$privateCount = 0

if (Test-Path -Path $privatePath) {
    $privateFiles = Get-ChildItem -Path "$privatePath\*.ps1" -Recurse -ErrorAction SilentlyContinue
    
    Write-Host "Loading private functions from $privatePath..." -ForegroundColor Cyan
    Write-Verbose "Found $($privateFiles.Count) private function files"
    
    foreach ($file in $privateFiles) {
        try {
            . $file.FullName
            $privateCount++
            Write-Verbose "Loaded private function: $($file.BaseName)"
        }
        catch {
            Write-Warning "Failed to import private function $($file.BaseName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "  ✓ Loaded $privateCount private functions" -ForegroundColor Green
}
else {
    Write-Warning "Private directory not found: $privatePath"
}

# Load public functions (to be exported)
$publicPath = Join-Path -Path $ModulePath -ChildPath 'Public'
$publicFunctions = @()
$publicCount = 0

if (Test-Path -Path $publicPath) {
    $publicFiles = Get-ChildItem -Path "$publicPath\*.ps1" -Recurse -ErrorAction SilentlyContinue
    
    Write-Host "Loading public functions from $publicPath..." -ForegroundColor Cyan
    Write-Verbose "Found $($publicFiles.Count) public function files"
    
    foreach ($file in $publicFiles) {
        try {
            . $file.FullName
            $publicCount++
            Write-Verbose "Loaded public function: $($file.BaseName)"
            
            # Extract function name from file content
            $fileContent = Get-Content -Path $file.FullName -Raw
            if ($fileContent -match 'function\s+([A-Za-z0-9\-_]+)') {
                $functionName = $matches[1]
                $publicFunctions += $functionName
                Write-Verbose "Added function to export list: $functionName"
            }
            else {
                Write-Warning "No function definition found in file: $($file.Name)"
            }
        }
        catch {
            Write-Warning "Failed to import public function $($file.BaseName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "  ✓ Loaded $publicCount public functions" -ForegroundColor Green
}
else {
    Write-Warning "Public directory not found: $publicPath"
}
#endregion

#region Export Functions
# Get all available functions in the module
$availableFunctions = Get-ChildItem function: | 
    Where-Object { $_.ScriptBlock.File -like "*$ModulePath*" } | 
    Select-Object -ExpandProperty Name

Write-Verbose "Available functions in module: $($availableFunctions -join ', ')"

# Remove any duplicates from the public functions list
$publicFunctions = $publicFunctions | Select-Object -Unique

# Export all public functions
if ($publicFunctions.Count -gt 0) {
    Export-ModuleMember -Function $publicFunctions
    
    # Display exported functions for verification
    Write-Host "Exported functions from $ModuleName module:" -ForegroundColor Cyan
    foreach ($function in $publicFunctions | Sort-Object) {
        Write-Host "  - $function" -ForegroundColor Yellow
    }
}
else {
    Write-Warning "No functions exported from $ModuleName module"
}
#endregion

# Display diagnostic information
Write-Host "`n===== DIAGNOSTIC INFORMATION =====" -ForegroundColor Magenta
Write-Host "Module path: $ModulePath" -ForegroundColor Magenta
Write-Host "Functions actually available in the module:" -ForegroundColor Magenta
$availableFunctions = Get-ChildItem function: | Where-Object { $_.ScriptBlock.File -like "*$ModulePath*" } | Select-Object -ExpandProperty Name
if ($availableFunctions) {
    foreach ($fn in $availableFunctions) {
        Write-Host "  - $fn" -ForegroundColor Magenta
    }
} else {
    Write-Host "  No functions found with this module path" -ForegroundColor Magenta
}

# Display loaded modules for verification
Write-Host "Currently loaded HomeLab modules:" -ForegroundColor Magenta
Get-Module | Where-Object { $_.Name -like "HomeLab.*" } | 
    Format-Table -Property Name, Version, Path -AutoSize

# Restore original preferences
$VerbosePreference = $originalVerbosePreference
$ErrorActionPreference = $originalErrorActionPreference
$WarningPreference = $originalWarningPreference
