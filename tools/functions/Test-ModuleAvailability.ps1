<#
.SYNOPSIS
    Tests if required modules are available
.DESCRIPTION
    Checks if all required modules are available and offers to install missing external modules
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Test-ModuleAvailability {
    [CmdletBinding()]
    param(
        [switch]$SkipModuleCheck
    )

    if (-not $script:RequiredModules) {
        Write-Log -Message "Required modules collection is not defined" -Level "Error"
        return $false
    }

    $allModulesAvailable = $true
    $modulesToInstall = @()

    foreach ($module in $script:RequiredModules) {
        $moduleName = $module.Name
        
        # For local modules, check if the file exists
        if ($module.Path) {
            if (-not (Test-Path -Path $module.Path)) {
                $allModulesAvailable = $false
                Write-Log -Message "Required local module not found: $($module.Path)" -Level "Warning"
            }
        }
        # For external modules like Az, check if they're installed
        else {
            $minVersion = $module.MinVersion
            $moduleInstalled = Get-Module -Name $moduleName -ListAvailable
            
            if (-not $moduleInstalled) {
                $allModulesAvailable = $false
                $modulesToInstall += $moduleName
                Write-Log -Message "Required external module not found: $moduleName" -Level "Warning"
            }
            elseif ($minVersion) {
                # Check version
                $latestVersion = ($moduleInstalled | Sort-Object Version -Descending | Select-Object -First 1).Version
                if ($latestVersion -lt [Version]$minVersion) {
                    $allModulesAvailable = $false
                    $modulesToInstall += $moduleName
                    Write-Log -Message "Module $moduleName version $latestVersion is below required version $minVersion" -Level "Warning"
                }
            }
        }
    }
    
    if (-not $allModulesAvailable -and -not $SkipModuleCheck) {
        Write-Log -Message "Some required modules are missing or outdated" -Level "Warning"
        
        # Only try to install external modules (like Az)
        if ($modulesToInstall.Count -gt 0) {
            $installModules = Read-Host "Would you like to install/update the missing external modules? (Y/N)"
            if ($installModules -eq "Y" -or $installModules -eq "y") {
                foreach ($moduleName in $modulesToInstall) {
                    try {
                        Write-Log -Message "Installing/updating module: $moduleName" -Level "Info"
                        Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -Confirm:$false
                        Write-Log -Message "Successfully installed/updated module: $moduleName" -Level "Success"
                    }
                    catch {
                        Write-Log -Message "Failed to install module $moduleName`: $_" -Level "Error"
                        return $false
                    }
                }
            }
            else {
                Write-Log -Message "User chose not to install missing modules" -Level "Warning"
                return $false
            }
        }
    }
    
    return $true
}

# Export the function
Export-ModuleMember -Function Test-ModuleAvailability
