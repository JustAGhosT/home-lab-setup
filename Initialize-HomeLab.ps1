# Initialize-HomeLab.ps1
# Safe initialization for HomeLab environment

# Save original preferences
$originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
$originalErrorActionPreference = $ErrorActionPreference

# Set safe preferences
$PSModuleAutoLoadingPreference = 'None'
$ErrorActionPreference = 'Continue'

try {
    # Set environment variables to prevent Azure module registration issues
    $env:AZURE_SKIP_MODULE_REGISTRATION = 'true'
    $env:AZURE_SKIP_CREDENTIAL_VALIDATION = 'true'
    
    # Determine the module path
    $scriptPath = $MyInvocation.MyCommand.Path
    $moduleRoot = Split-Path -Path (Split-Path -Path $scriptPath -Parent) -Parent
    $modulePath = Join-Path -Path $moduleRoot -ChildPath "HomeLab.Core"
    
    Write-Verbose "Looking for HomeLab.Core module at: $modulePath"
    
    # Try to import the module from the relative path first
    if (Test-Path -Path $modulePath) {
        Write-Verbose "Importing HomeLab.Core module from: $modulePath"
        Import-Module -Name $modulePath -Force -DisableNameChecking
    }
    # Fall back to the installed module
    elseif (Get-Module -Name HomeLab.Core -ListAvailable) {
        Write-Verbose "Importing installed HomeLab.Core module"
        Import-Module -Name HomeLab.Core -Force -DisableNameChecking
    }
    else {
        Write-Warning "HomeLab.Core module not found. Please install it first."
        return
    }
    
    # Verify the module was loaded
    if (-not (Get-Module -Name HomeLab.Core)) {
        Write-Error "Failed to load HomeLab.Core module."
        return
    }
    
    # Check if Setup-HomeLab function is available
    if (Get-Command -Name Setup-HomeLab -ErrorAction SilentlyContinue) {
        Write-Verbose "Running Setup-HomeLab..."
        Setup-HomeLab
    }
    elseif (Get-Command -Name Initialize-HomeLab -ErrorAction SilentlyContinue) {
        Write-Verbose "Running Initialize-HomeLab..."
        Initialize-HomeLab
    }
    else {
        Write-Error "Neither Setup-HomeLab nor Initialize-HomeLab function found in the loaded module."
    }
    
    # Load Az.Accounts module if needed for Azure operations
    if (-not (Get-Module -Name Az.Accounts) -and (Get-Module -Name Az.Accounts -ListAvailable)) {
        Write-Verbose "Importing Az.Accounts module..."
        Import-Module -Name Az.Accounts -DisableNameChecking -Global
    }
    
    Write-Verbose "HomeLab environment initialized successfully."
}
catch {
    Write-Error "Error initializing HomeLab environment: $_"
}
finally {
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $ErrorActionPreference = $originalErrorActionPreference
}
