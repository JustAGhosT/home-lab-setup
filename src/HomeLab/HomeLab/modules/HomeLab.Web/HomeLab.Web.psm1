# HomeLab.Web Module
# Contains functions for deploying and managing websites in Azure

# Import all functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue)

# Import Private functions
foreach ($import in $Private) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Import Public functions
foreach ($import in $Public) {
    try {
        . $import.FullName
        Export-ModuleMember -Function $import.BaseName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}