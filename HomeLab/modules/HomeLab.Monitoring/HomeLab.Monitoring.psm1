<#
.SYNOPSIS
    HomeLab Module Template
.DESCRIPTION
    Template for HomeLab modules with safe function loading.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable function discovery debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'

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

# Export all public functions
Export-ModuleMember -Function $PublicFunctionNames

# Restore automatic module loading
$PSModuleAutoLoadingPreference = 'All'
