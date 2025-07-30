<#
.SYNOPSIS
    Imports all required modules
.DESCRIPTION
    Imports all required modules in the correct order, handling dependencies
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Import-RequiredModules {
    [CmdletBinding()]
    param(
        [switch]$ForceReload
    )

    if (-not $script:RequiredModules) {
        Write-Log -Message "Required modules collection is not defined" -Level "Error"
        return $false
    }

    # First import HomeLab.Logging as it's needed by other modules
    $loggingModule = $script:RequiredModules | Where-Object { $_.Name -eq "HomeLab.Logging" }
    if ($loggingModule) {
        try {
            Write-Host "Loading module: HomeLab.Logging" -ForegroundColor Yellow
            Import-Module -Name $loggingModule.Path -Force:$ForceReload -ErrorAction Stop -Global
            Write-Log -Message "Successfully loaded module: HomeLab.Logging" -Level "Success"
        }
        catch {
            Write-Host "Failed to load HomeLab.Logging module: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Then import HomeLab.Core as it may be needed by other modules
    $coreModule = $script:RequiredModules | Where-Object { $_.Name -eq "HomeLab.Core" }
    if ($coreModule) {
        try {
            Write-Log -Message "Loading module: HomeLab.Core" -Level "Info"
            Import-Module -Name $coreModule.Path -Force:$ForceReload -ErrorAction Stop -Global
            Write-Log -Message "Successfully loaded module: HomeLab.Core" -Level "Success"
        }
        catch {
            Write-Log -Message "Failed to load HomeLab.Core module: $_" -Level "Error"
            return $false
        }
    }
    
    # Import the rest of the modules
    foreach ($module in $script:RequiredModules) {
        $moduleName = $module.Name
        
        # Skip already imported modules
        if ($moduleName -eq "HomeLab.Logging" -or $moduleName -eq "HomeLab.Core") {
            continue
        }
        
        try {
            Write-Log -Message "Loading module: $moduleName" -Level "Info"
            
            # For local modules, use the Path
            if ($module.Path) {
                Import-Module -Name $module.Path -Force:$ForceReload -ErrorAction Stop -Global
            }
            # For external modules like Az, use the Name
            else {
                Import-Module -Name $moduleName -Force:$ForceReload -ErrorAction Stop
            }
            
            Write-Log -Message "Successfully loaded module: $moduleName" -Level "Success"
        }
        catch {
            Write-Log -Message "Failed to load module $moduleName`: $_" -Level "Error"
            # Continue loading other modules even if one fails
        }
    }
    
    $script:ModulesLoaded = $true
    return $true
}

# Export the function
Export-ModuleMember -Function Import-RequiredModules
