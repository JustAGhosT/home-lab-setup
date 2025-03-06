<#
.SYNOPSIS
    HomeLab UI Helpers Module
.DESCRIPTION
    Provides user interface helper functions for HomeLab.
    This includes core UI functions (Pause, Show-Spinner, Get-UserConfirmation),
    as well as menu display functions and menu handler functions.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

# Define paths for Public and Private function files
$ModulePath = $PSScriptRoot
$PublicPath = Join-Path -Path $ModulePath -ChildPath "Public"
$PrivatePath = Join-Path -Path $ModulePath -ChildPath "Private"
$MenuPath = Join-Path -Path $PublicPath -ChildPath "menu"
$HandlersPath = Join-Path -Path $PublicPath -ChildPath "handlers"

# Core UI helper functions
function Pause {
    [CmdletBinding()]
    param()
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Spinner {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Activity = "Processing",
        
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 1
    )
    
    $spinner = @('|', '/', '-', '\')
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    
    $i = 0
    while ((Get-Date) -lt $endTime) {
        Write-Host "`r$Activity $($spinner[$i % 4])" -NoNewline
        [Console]::Out.Flush()
        Start-Sleep -Milliseconds 250
        $i++
    }
    Write-Host "`r$Activity Complete!     "
    [Console]::Out.Flush()
}

function Get-UserConfirmation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$DefaultYes
    )
    
    $prompt = if ($DefaultYes) { "$Message (Y/n): " } else { "$Message (y/N): " }
    Write-Host $prompt -NoNewline -ForegroundColor Yellow
    [Console]::Out.Flush()
    
    $response = Read-Host
    if ($DefaultYes) {
        return ($response -ne "n" -and $response -ne "N")
    }
    else {
        return ($response -eq "y" -or $response -eq "Y")
    }
}

# Import private functions
$PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported private function file: $($Function.FullName)"
    }
    catch {
        Write-Error "Failed to import private function file $($Function.FullName): $_"
    }
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported public function file: $($Function.FullName)"
    }
    catch {
        Write-Error "Failed to import public function file $($Function.FullName): $_"
    }
}

# Import menu display functions
$MenuFunctions = Get-ChildItem -Path $MenuPath -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $MenuFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported menu function file: $($Function.FullName)"
    }
    catch {
        Write-Error "Failed to import menu function file $($Function.FullName): $_"
    }
}

# Import menu handler functions
$HandlerFunctions = Get-ChildItem -Path $HandlersPath -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $HandlerFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported handler function file: $($Function.FullName)"
    }
    catch {
        Write-Error "Failed to import handler function file $($Function.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function Pause, Show-Spinner, Get-UserConfirmation

# Export menu display functions
Export-ModuleMember -Function Show-Menu, Show-MainMenu, Show-DeployMenu, Show-VpnCertMenu, 
                     Show-VpnGatewayMenu, Show-VpnClientMenu, Show-NatGatewayMenu, 
                     Show-DocumentationMenu, Show-SettingsMenu, Show-DeploymentSummary

# Export menu handler functions
Export-ModuleMember -Function Invoke-DeployMenu, Invoke-VpnCertMenu, Invoke-VpnGatewayMenu,
                     Invoke-VpnClientMenu, Invoke-NatGatewayMenu, Invoke-DocumentationMenu,
                     Invoke-SettingsMenu
