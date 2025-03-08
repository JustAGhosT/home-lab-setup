<#
.SYNOPSIS
    HomeLab Azure Module
.DESCRIPTION
    Module for HomeLab Azure infrastructure deployment with safe function loading.
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

    # Create an array to store public function names
    $PublicFunctionNames = @()

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
            
            # If public, add to export list
            if ($IsPublic) {
                $script:PublicFunctionNames += $functionName
            }
            
            Write-Verbose "Imported $(if ($IsPublic) {'public'} else {'private'}) function: $functionName"
            return $true
        }
        catch {
            Write-Warning "Failed to import function from $FilePath`: $_"
            return $false
        }
    }

    # Safe function to check if a command exists without triggering auto-loading
    function Test-CommandExistsSafely {
        param (
            [string]$CommandName
        )
        
        # First check if it's already loaded without triggering auto-loading
        $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        
        return ($null -ne $command)
    }

    # ===== AZURE MODULE PROTECTION =====
    # Save original Azure module-related environment variables
    $originalAzureEnvVars = @{}
    Get-ChildItem env: | Where-Object { $_.Name -like 'AZURE_*' -or $_.Name -like 'AZ_*' } | ForEach-Object {
        $originalAzureEnvVars[$_.Name] = $_.Value
    }

    # Temporarily set environment variable to prevent Az module auto-registration
    $env:AZURE_SKIP_MODULE_REGISTRATION = 'true'

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

    # Define fallback functions if they don't exist
    $RequiredFunctions = @(
        'Deploy-Infrastructure',
        'NatGatewayEnableDisable',
        'Connect-AzureAccount',
        'Test-ResourceGroup',
        'Reset-ResourceGroup'
    )

    foreach ($FunctionName in $RequiredFunctions) {
        if (-not (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue)) {
            # Create a placeholder function
            $scriptBlock = [ScriptBlock]::Create(@"
                function $FunctionName {
                    [CmdletBinding()]
                    param()
                    Write-Warning "Function $FunctionName is a placeholder. Implement the actual function in Public/$FunctionName.ps1"
                }
"@)
            . $scriptBlock
            $PublicFunctionNames += $FunctionName
        }
    }

    # Check if Write-Log function is available
    $canLog = $false
    try {
        if (Test-CommandExistsSafely -CommandName "Write-SimpleLog") {
            $canLog = $true
            Write-SimpleLog -Message "$ModuleName module loaded successfully" -Level SUCCESS
        }
        elseif (Test-CommandExistsSafely -CommandName "Write-Log") {
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

    # Export all public functions and the helper functions
    Export-ModuleMember -Function ($PublicFunctionNames + @('Import-ScriptFileSafely', 'Test-CommandExistsSafely'))
}
finally {
    # ===== CLEANUP SECTION =====
    # Reset module loading guard
    $script:IsLoading = $false
    
    # Restore original Azure environment variables
    if ($originalAzureEnvVars) {
        foreach ($key in $originalAzureEnvVars.Keys) {
            if ($originalAzureEnvVars[$key] -eq $null) {
                Remove-Item -Path "env:$key" -ErrorAction SilentlyContinue
            }
            else {
                Set-Item -Path "env:$key" -Value $originalAzureEnvVars[$key]
            }
        }
    }
    
    # Display functions defined in this module
    $moduleFunctions = Get-ChildItem -Path Function:\ | Where-Object {
        $_.ScriptBlock.File -and $_.ScriptBlock.File.Contains($ModulePath)
    } | Select-Object -ExpandProperty Name

    Write-Host "Functions defined in this module:" -ForegroundColor Cyan
    $moduleFunctions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
    
    # Remove temporary environment variables
    Remove-Item -Path "env:AZURE_SKIP_MODULE_REGISTRATION" -ErrorAction SilentlyContinue
    
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
}
