<#
.SYNOPSIS
    HomeLab Logging Module
.DESCRIPTION
    Advanced logging module for HomeLab projects with console and file output capabilities
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
    Version: 1.0.0
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

#region Module Variables
# Default log settings
$script:LogPath = Join-Path -Path $env:TEMP -ChildPath "HomeLab\Logs\HomeLab.log"
$script:LogLevel = "Info"  # Default log level (Debug, Info, Warning, Error, Success)
$script:LogFileRotationEnabled = $true
$script:LogFileMaxSizeMB = 10
$script:LogFileMaxCount = 5
#endregion

#region Function Loading
# Load private functions (internal to the module)
$privatePath = Join-Path -Path $ModulePath -ChildPath 'Private'
$privateCount = 0

if (Test-Path -Path $privatePath) {
    $privateFiles = Get-ChildItem -Path "$privatePath\*.ps1" -ErrorAction SilentlyContinue
    
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
    
    Write-Host "  SUCCESS: Loaded $privateCount private functions" -ForegroundColor Green
}
else {
    Write-Warning "Private directory not found: $privatePath"
}

# Load public functions (to be exported)
$publicPath = Join-Path -Path $ModulePath -ChildPath 'Public'
$publicCount = 0

if (Test-Path -Path $publicPath) {
    $publicFiles = Get-ChildItem -Path "$publicPath\*.ps1" -ErrorAction SilentlyContinue
    
    Write-Host "Loading public functions from $publicPath..." -ForegroundColor Cyan
    Write-Verbose "Found $($publicFiles.Count) public function files"
    
    foreach ($file in $publicFiles) {
        try {
            . $file.FullName
            $publicCount++
            Write-Verbose "Loaded public function: $($file.BaseName)"
        }
        catch {
            Write-Warning "Failed to import public function $($file.BaseName): $($_.Exception.Message)"
        }
    }
    
    Write-Host "  SUCCESS: Loaded $publicCount public functions" -ForegroundColor Green
}
else {
    Write-Warning "Public directory not found: $publicPath"
}
#endregion

#region Module Finalization
# Display loading summary
Write-Host "$ModuleName module loaded successfully" -ForegroundColor Green

# Export public functions
$functionsToExport = @(
    'Write-Log', 
    'Get-LogEntries', 
    'Get-LogPath', 
    'Initialize-Logging', 
    'Set-LogFileRotation', 
    'Set-LogLevel', 
    'Set-LogPath',
    'Write-ColorOutput',
    'Write-SafeLog',
    'Write-SimpleLog',
    'Write-InfoLog',
    'Write-WarningLog',
    'Write-SuccessLog',
    'Write-ErrorLog',
    'Write-DebugLog'
)

# Export the functions
Export-ModuleMember -Function $functionsToExport
Export-ModuleMember -Variable 'LogPath', 'LogLevel', 'LogFileRotationEnabled', 'LogFileMaxSizeMB', 'LogFileMaxCount'

# Display diagnostic information
Write-Host "`n===== DIAGNOSTIC INFORMATION =====" -ForegroundColor Magenta
Write-Host "Module path: $ModulePath" -ForegroundColor Magenta
Write-Host "Functions exported from the module:" -ForegroundColor Magenta
foreach ($fn in $functionsToExport) {
    Write-Host "  - $fn" -ForegroundColor Magenta
}

# Restore original preferences
$VerbosePreference = $originalVerbosePreference
$ErrorActionPreference = $originalErrorActionPreference
$WarningPreference = $originalWarningPreference
#endregion
