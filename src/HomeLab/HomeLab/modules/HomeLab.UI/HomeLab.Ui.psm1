<#
.SYNOPSIS
    HomeLab.UI PowerShell Module
.DESCRIPTION
    A PowerShell module for managing HomeLab Azure infrastructure through a text-based UI.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Save original preferences to restore later
$originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
$originalDebugPreference = $DebugPreference
$originalVerbosePreference = $VerbosePreference
$originalErrorActionPreference = $ErrorActionPreference

# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'
# Control verbosity
$VerbosePreference = 'SilentlyContinue'
# Make errors non-terminating
$ErrorActionPreference = 'Continue'

# Create a guard to prevent recursive loading
if ($script:IsLoading) {
    Write-Warning "Module is already loading. Preventing recursive loading."
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
    return
}
$script:IsLoading = $true

try {
    # Get the directory where this script is located
    $ModulePath = $PSScriptRoot
    $ModuleName = (Get-Item $PSScriptRoot).BaseName

    # Define the functions to export based on the manifest
    $FunctionsToExport = @(
        # Main functions
        'Show-DeploymentSummary',
        'Show-Menu',
        
        # Menu display functions
        'Show-DeployMenu',
        'Show-VpnCertMenu',
        'Show-VpnGatewayMenu',
        'Show-VpnClientMenu',
        'Show-NatGatewayMenu',
        'Show-DocumentationMenu',
        'Show-SettingsMenu',
        'Show-MainMenu',
        
        # Menu handler functions
        'Invoke-MainMenu',
        'Invoke-DeployMenu',
        'Invoke-VpnCertMenu',
        'Invoke-VpnGatewayMenu',
        'Invoke-VpnClientMenu',
        'Invoke-NatGatewayMenu',
        'Invoke-DocumentationMenu',
        'Invoke-SettingsMenu',
        
        # Utility functions
        'Write-ColorOutput',
        'Clear-CurrentLine',
        'Get-WindowSize',
        
        # Progress bar functions
        'Show-ProgressBar',
        'Start-ProgressTask',
        'Update-ProgressBar',
        
        # Deployment module functions
        'Invoke-FullDeployment',
        'Invoke-NetworkDeployment',
        'Invoke-VPNGatewayDeployment',
        'Invoke-NATGatewayDeployment',
        'Show-DeploymentStatus',
        'Show-BackgroundMonitoringStatus'
    )

    # Load private functions
    $privatePath = Join-Path -Path $ModulePath -ChildPath "Private"
    if (Test-Path -Path $privatePath) {
        $privateFiles = Get-ChildItem -Path $privatePath -Filter "*.ps1" -Recurse
        foreach ($file in $privateFiles) {
            try {
                . $file.FullName
                Write-Verbose "Imported private function file: $($file.Name)"
            }
            catch {
                Write-Error "Failed to import private function file: $($file.FullName): $_"
            }
        }
    }

    # Load public functions - handlers
    $handlersPath = Join-Path -Path $ModulePath -ChildPath "Public\Handlers"
    if (Test-Path -Path $handlersPath) {
        $handlerFiles = Get-ChildItem -Path $handlersPath -Filter "*.ps1" -Recurse
        foreach ($file in $handlerFiles) {
            try {
                . $file.FullName
                Write-Verbose "Imported handler function file: $($file.Name)"
            }
            catch {
                Write-Error "Failed to import handler function file: $($file.FullName): $_"
            }
        }
    }

    # Load public functions - menu
    $menuPath = Join-Path -Path $ModulePath -ChildPath "Public\Menu"
    if (Test-Path -Path $menuPath) {
        $menuFiles = Get-ChildItem -Path $menuPath -Filter "*.ps1" -Recurse
        foreach ($file in $menuFiles) {
            try {
                . $file.FullName
                Write-Verbose "Imported menu function file: $($file.Name)"
            }
            catch {
                Write-Error "Failed to import menu function file: $($file.FullName): $_"
            }
        }
    }
    
    # Load deployment module functions
    $deploymentModulePath = Join-Path -Path $ModulePath -ChildPath "Public\DeploymentModule"
    if (Test-Path -Path $deploymentModulePath) {
        $deploymentFiles = Get-ChildItem -Path $deploymentModulePath -Filter "*.ps1" -Recurse
        foreach ($file in $deploymentFiles) {
            try {
                . $file.FullName
                Write-Verbose "Imported deployment module function file: $($file.Name)"
            }
            catch {
                Write-Error "Failed to import deployment module function file: $($file.FullName): $_"
            }
        }
    }

    # Load other public functions
    $publicPath = Join-Path -Path $ModulePath -ChildPath "Public"
    $otherPublicFiles = Get-ChildItem -Path $publicPath -Filter "*.ps1" -Exclude "Handlers", "Menu", "DeploymentModule" -Recurse
    foreach ($file in $otherPublicFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported public function file: $($file.Name)"
        }
        catch {
            Write-Error "Failed to import public function file: $($file.FullName): $_"
        }
    }

    # Display functions defined in this module
    $moduleFunctions = Get-ChildItem -Path Function:\ | Where-Object {
        $_.ScriptBlock.File -and $_.ScriptBlock.File.Contains($ModulePath)
    } | Select-Object -ExpandProperty Name

    Write-Host "Functions defined in this module:" -ForegroundColor Cyan
    if ($moduleFunctions) {
        $moduleFunctions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
    } else {
        # Fallback to listing all functions that match our export list
        $FunctionsToExport | ForEach-Object { 
            if (Get-Command -Name $_ -ErrorAction SilentlyContinue) {
                Write-Host "  - $_" -ForegroundColor Cyan 
            }
        }
    }

    # Export public functions
    Export-ModuleMember -Function $FunctionsToExport
}
finally {
    # Reset module loading guard
    $script:IsLoading = $false
    
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
}
