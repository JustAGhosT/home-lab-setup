<#
.SYNOPSIS
    Safely imports a PowerShell module with error handling
.DESCRIPTION
    Attempts to import a PowerShell module from a specified path with comprehensive error handling.
    Returns a boolean indicating success or failure of the import operation.
.PARAMETER ModulePath
    The full path to the module file (.psm1) to import
.PARAMETER ModuleName
    The name of the module being imported (used for logging)
.PARAMETER Force
    If specified, forces the module to be reloaded even if it's already loaded
.EXAMPLE
    Import-SafeModule -ModulePath "C:\Modules\MyModule.psm1" -ModuleName "MyModule"
    Attempts to import the MyModule module and returns $true if successful
.NOTES
    Part of the HomeLab.Core module
#>
function Import-SafeModule {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Check if module file exists
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Warning "Module file not found: $ModulePath"
        return $false
    }
    
    try {
        # Check if module is already loaded
        $moduleLoaded = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        
        if ($moduleLoaded -and -not $Force) {
            Write-Verbose "Module $ModuleName is already loaded."
            return $true
        }
        
        # Import the module
        Import-Module -Name $ModulePath -Force -Global -DisableNameChecking -ErrorAction Stop
        
        # Verify the module was loaded
        $moduleLoaded = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        
        if ($moduleLoaded) {
            Write-Verbose "Successfully loaded module: $ModuleName"
            return $true
        }
        else {
            Write-Warning "Module $ModuleName was not loaded correctly after import attempt."
            return $false
        }
    }
    catch {
        Write-Warning "Error importing module $ModuleName`: $_"
        return $false
    }
}

# Export the function
Export-ModuleMember -Function Import-SafeModule
