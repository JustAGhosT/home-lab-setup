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
    param()

    if (-not $script:RequiredModules) {
        Write-Error "Required modules collection is not defined"
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
                Write-Warning "Required local module not found: $($module.Path)"
            }
        }
        # For external modules like Az, check if they're installed
        else {
            $minVersion = $module.MinVersion
            $moduleInstalled = Get-Module -Name $moduleName -ListAvailable
            
            if (-not $moduleInstalled) {
                $allModulesAvailable = $false
                $modulesToInstall += $moduleName
                Write-Warning "Required external module not found: $moduleName"
            }
            elseif ($minVersion) {
                # Check version
                $latestVersion = ($moduleInstalled | Sort-Object Version -Descending | Select-Object -First 1).Version
                if ($latestVersion -lt [Version]$minVersion) {
                    $allModulesAvailable = $false
                    $modulesToInstall += $moduleName
                    Write-Warning "Module $moduleName version $latestVersion is below required version $minVersion"
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
                        Write-Host "Installing/updating module: $moduleName" -ForegroundColor Yellow
                        Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -Confirm:$false
                        Write-Host "Successfully installed/updated module: $moduleName" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "Failed to install module $moduleName`: $_"
                        return $false
                    }
                }
            }
            else {
                Write-Warning "User chose not to install missing modules"
                return $false
            }
        }
    }
    
    return $true
}

# Export the function
Export-ModuleMember -Function Test-ModuleAvailability
