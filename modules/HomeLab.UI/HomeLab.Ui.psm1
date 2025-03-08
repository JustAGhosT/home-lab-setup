<#
.SYNOPSIS
    HomeLab.UI PowerShell Module
.DESCRIPTION
    A PowerShell module for managing HomeLab Azure infrastructure through a text-based UI.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
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
        'Show-MainMenu',
        'Show-Menu',
        'Show-DeploymentSummary',
        
        # Menu display functions
        'Show-DeployMenu',
        'Show-VpnCertMenu',
        'Show-VpnGatewayMenu',
        'Show-VpnClientMenu',
        'Show-NatGatewayMenu',
        'Show-DocumentationMenu',
        'Show-SettingsMenu',
        
        # Menu handler functions
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
        'Update-ProgressBar'
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
    $handlersPath = Join-Path -Path $ModulePath -ChildPath "Public\handlers"
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
    $menuPath = Join-Path -Path $ModulePath -ChildPath "Public\menu"
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

    # Load other public functions
    $publicPath = Join-Path -Path $ModulePath -ChildPath "Public"
    $otherPublicFiles = Get-ChildItem -Path $publicPath -Filter "*.ps1" -Exclude "handlers", "menu" -Recurse
    foreach ($file in $otherPublicFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported public function file: $($file.Name)"
        }
        catch {
            Write-Error "Failed to import public function file: $($file.FullName): $_"
        }
    }

    # Define essential UI functions if they don't exist
    if (-not (Get-Command -Name 'Write-ColorOutput' -ErrorAction SilentlyContinue)) {
        function Write-ColorOutput {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
                [string]$Message,
                
                [Parameter(Mandatory = $false)]
                [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
                
                [Parameter(Mandatory = $false)]
                [System.ConsoleColor]$BackgroundColor = [System.ConsoleColor]::Black,
                
                [Parameter(Mandatory = $false)]
                [switch]$NoNewLine
            )
            
            $originalFgColor = [Console]::ForegroundColor
            $originalBgColor = [Console]::BackgroundColor
            
            try {
                [Console]::ForegroundColor = $ForegroundColor
                [Console]::BackgroundColor = $BackgroundColor
                
                if ($NoNewLine) {
                    Write-Host $Message -NoNewline
                }
                else {
                    Write-Host $Message
                }
            }
            finally {
                [Console]::ForegroundColor = $originalFgColor
                [Console]::BackgroundColor = $originalBgColor
            }
        }
        Write-Verbose "Created essential function: Write-ColorOutput"
    }
    
    if (-not (Get-Command -Name 'Clear-CurrentLine' -ErrorAction SilentlyContinue)) {
        function Clear-CurrentLine {
            [CmdletBinding()]
            param()
            
            $cursorPosition = $host.UI.RawUI.CursorPosition
            $cursorPosition.X = 0
            $host.UI.RawUI.CursorPosition = $cursorPosition
            
            $windowSize = $host.UI.RawUI.WindowSize
            $clearLine = " " * ($windowSize.Width - 1)
            
            Write-Host $clearLine -NoNewline
            $host.UI.RawUI.CursorPosition = $cursorPosition
        }
        Write-Verbose "Created essential function: Clear-CurrentLine"
    }
    
    if (-not (Get-Command -Name 'Get-WindowSize' -ErrorAction SilentlyContinue)) {
        function Get-WindowSize {
            [CmdletBinding()]
            param()
            
            return $host.UI.RawUI.WindowSize
        }
        Write-Verbose "Created essential function: Get-WindowSize"
    }

    # Define menu display functions if they don't exist
    $menuDisplayFunctions = @(
        'Show-MainMenu',
        'Show-DeployMenu',
        'Show-VpnCertMenu',
        'Show-VpnGatewayMenu',
        'Show-VpnClientMenu',
        'Show-NatGatewayMenu',
        'Show-DocumentationMenu',
        'Show-SettingsMenu',
        'Show-DeploymentSummary',
        'Show-Menu'
    )
    
    foreach ($functionName in $menuDisplayFunctions) {
        if (-not (Get-Command -Name $functionName -ErrorAction SilentlyContinue)) {
            # Create a placeholder menu function
            $scriptBlock = [ScriptBlock]::Create(@"
                function $functionName {
                    [CmdletBinding()]
                    param(
                        [Parameter(Mandatory = `$false)]
                        [hashtable]`$Options,
                        
                        [Parameter(Mandatory = `$false)]
                        [string]`$Title = "$functionName",
                        
                        [Parameter(Mandatory = `$false)]
                        [switch]`$ReturnToMain
                    )
                    
                    Write-ColorOutput "$functionName - Placeholder function" -ForegroundColor Yellow
                    Write-Warning "Function $functionName is a placeholder. Implement the actual function in Public/menu/$functionName.ps1"
                }
"@)
            . $scriptBlock
            Write-Verbose "Created placeholder for menu function: $functionName"
        }
    }
    
    # Define menu handler functions if they don't exist
    $menuHandlerFunctions = @(
        'Invoke-DeployMenu',
        'Invoke-VpnCertMenu',
        'Invoke-VpnGatewayMenu',
        'Invoke-VpnClientMenu',
        'Invoke-NatGatewayMenu',
        'Invoke-DocumentationMenu',
        'Invoke-SettingsMenu'
    )
    
    foreach ($functionName in $menuHandlerFunctions) {
        if (-not (Get-Command -Name $functionName -ErrorAction SilentlyContinue)) {
            # Create a placeholder handler function
            $scriptBlock = [ScriptBlock]::Create(@"
                function $functionName {
                    [CmdletBinding()]
                    param(
                        [Parameter(Mandatory = `$false)]
                        [string]`$Selection,
                        
                        [Parameter(Mandatory = `$false)]
                        [hashtable]`$State
                    )
                    
                    Write-ColorOutput "$functionName - Placeholder handler for selection: `$Selection" -ForegroundColor Yellow
                    Write-Warning "Function $functionName is a placeholder. Implement the actual function in Public/handlers/$functionName.ps1"
                    
                    return `$State
                }
"@)
            . $scriptBlock
            Write-Verbose "Created placeholder for handler function: $functionName"
        }
    }

    # Check if Write-Log function is available
    $canLog = $false
    try {
        if (Get-Command -Name "Write-SimpleLog" -ErrorAction SilentlyContinue) {
            $canLog = $true
            Write-SimpleLog -Message "$ModuleName module loaded successfully" -Level SUCCESS
        }
        elseif (Get-Command -Name "Write-Log" -ErrorAction SilentlyContinue) {
            $canLog = $true
            Write-Log -Message "$ModuleName module loaded successfully" -Level INFO
        }
    }
    catch {
        # Silently continue if logging fails
    }

    if (-not $canLog) {
        Write-Host "$ModuleName module loaded successfully" -ForegroundColor Green
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
