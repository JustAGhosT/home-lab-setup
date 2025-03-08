<#
.SYNOPSIS
    HomeLab Security Module
.DESCRIPTION
    Module for HomeLab security functions with safe function loading.
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
    # Get the module path
    $ModulePath = $PSScriptRoot
    $ModuleName = (Get-Item $PSScriptRoot).BaseName

    # Function to safely import script files
    function Import-ScriptFileSafely {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $false)]
            [switch]$IsPublic
        )
        
        if (-not (Test-Path -Path $FilePath)) {
            Write-Warning "File not found: $FilePath"
            return $false
        }
        
        try {
            # Extract function name from file name
            $functionName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
            
            # Read file content
            $fileContent = Get-Content -Path $FilePath -Raw -ErrorAction Stop
            
            # Create a script block and execute it in the current scope
            $scriptBlock = [ScriptBlock]::Create($fileContent)
            . $scriptBlock
            
            Write-Verbose "Imported $(if ($IsPublic) {'public'} else {'private'}) function: $functionName"
            return $true
        }
        catch {
            Write-Warning "Failed to import function from $FilePath`: $_"
            return $false
        }
    }

    # Import private functions
    $PrivateFunctions = Get-ChildItem -Path "$ModulePath\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue
    foreach ($Function in $PrivateFunctions) {
        Import-ScriptFileSafely -FilePath $Function.FullName
    }

    # Import public functions
    $PublicFunctions = Get-ChildItem -Path "$ModulePath\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue
    foreach ($Function in $PublicFunctions) {
        Import-ScriptFileSafely -FilePath $Function.FullName -IsPublic
    }

    # CRITICAL FIX: Define all required functions explicitly
    # VPN Certificate Management
    function New-VpnRootCertificate {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$CertName = "HomeLab-VPN-Root",
            
            [Parameter(Mandatory = $false)]
            [string]$OutputPath = "$env:USERPROFILE\.homelab\certs"
        )
        
        Write-Warning "Function New-VpnRootCertificate is a placeholder. Implement the actual function in Public/New-VpnRootCertificate.ps1"
    }

    function New-VpnClientCertificate {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ClientName,
            
            [Parameter(Mandatory = $false)]
            [string]$RootCertPath = "$env:USERPROFILE\.homelab\certs\HomeLab-VPN-Root.pfx"
        )
        
        Write-Warning "Function New-VpnClientCertificate is a placeholder. Implement the actual function in Public/New-VpnClientCertificate.ps1"
    }

    function Add-VpnGatewayCertificate {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$CertPath = "$env:USERPROFILE\.homelab\certs\HomeLab-VPN-Root.pfx"
        )
        
        Write-Warning "Function Add-VpnGatewayCertificate is a placeholder. Implement the actual function in Public/Add-VpnGatewayCertificate.ps1"
    }

    function Get-VpnCertificate {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$CertName = "*HomeLab*"
        )
        
        Write-Warning "Function Get-VpnCertificate is a placeholder. Implement the actual function in Public/Get-VpnCertificate.ps1"
    }

    # VPN Client Management
    function Add-VpnComputer {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ComputerName,
            
            [Parameter(Mandatory = $true)]
            [string]$GatewayIP,
            
            [Parameter(Mandatory = $false)]
            [string]$CertPath
        )
        
        Write-Warning "Function Add-VpnComputer is a placeholder. Implement the actual function in Public/Add-VpnComputer.ps1"
    }

    function Connect-Vpn {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$ConnectionName = "HomeLab-VPN"
        )
        
        Write-Warning "Function Connect-Vpn is a placeholder. Implement the actual function in Public/Connect-Vpn.ps1"
    }

    function Disconnect-Vpn {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$ConnectionName = "HomeLab-VPN"
        )
        
        Write-Warning "Function Disconnect-Vpn is a placeholder. Implement the actual function in Public/Disconnect-Vpn.ps1"
    }

    function Get-VpnConnectionStatus {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [string]$ConnectionName = "HomeLab-VPN"
        )
        
        Write-Warning "Function Get-VpnConnectionStatus is a placeholder. Implement the actual function in Public/Get-VpnConnectionStatus.ps1"
    }

    # Set up alias for backward compatibility
    New-Alias -Name 'New-AdditionalClientCertificate' -Value 'New-VpnClientCertificate' -ErrorAction SilentlyContinue

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
    $moduleFunctions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }

    # CRITICAL FIX: Explicitly export all required functions
    Export-ModuleMember -Function @(
        'Import-ScriptFileSafely',
        'New-VpnRootCertificate',
        'New-VpnClientCertificate',
        'Add-VpnGatewayCertificate',
        'Get-VpnCertificate',
        'Add-VpnComputer',
        'Connect-Vpn',
        'Disconnect-Vpn',
        'Get-VpnConnectionStatus'
    ) -Alias 'New-AdditionalClientCertificate'
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
