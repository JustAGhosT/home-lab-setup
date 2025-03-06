<#
.SYNOPSIS
    HomeLab.Azure Module
.DESCRIPTION
    Provides Azure infrastructure deployment functionality for HomeLab,
    including deploying full or component-based infrastructure and enabling/disabling NAT Gateways.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

# Define paths for Public and Private function files
$ModulePath = $PSScriptRoot
$PublicPath = Join-Path -Path $ModulePath -ChildPath "Public"
$PrivatePath = Join-Path -Path $ModulePath -ChildPath "Private"

# Import private functions first (they may be used by public functions)
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

# Log module load
Write-Log -Message "HomeLab.Azure module loaded successfully" -Level Info

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
