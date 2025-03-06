<#
.SYNOPSIS
    Helper functions for the HomeLab.Core module.
.DESCRIPTION
    Contains internal helper functions used by the HomeLab.Core module.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

<#
.SYNOPSIS
    Checks if a path is valid.
.DESCRIPTION
    Validates if a path is valid and can be used for file operations.
.PARAMETER Path
    The path to validate.
.EXAMPLE
    Test-ValidPath -Path "C:\Temp\file.txt"
.OUTPUTS
    Boolean. Returns $true if the path is valid, $false otherwise.
#>
function Test-ValidPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        # Check if the path is valid by attempting to get its parent directory
        $parentPath = Split-Path -Path $Path -Parent
        
        # If the parent path is empty, it might be a root path like "C:\"
        if ([string]::IsNullOrEmpty($parentPath)) {
            return $true
        }
        
        # Check if the parent directory exists or can be created
        if (-not (Test-Path -Path $parentPath)) {
            # Try to create the directory to see if it's a valid path
            $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
            
            # If we get here, the directory was created successfully, so clean it up
            Remove-Item -Path $parentPath -Force -ErrorAction SilentlyContinue
        }
        
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Converts a PSObject to a hashtable.
.DESCRIPTION
    Converts a PowerShell object to a hashtable recursively.
.PARAMETER InputObject
    The object to convert.
.EXAMPLE
    $hashtable = ConvertTo-Hashtable -InputObject $someObject
.OUTPUTS
    Hashtable. Returns a hashtable representation of the input object.
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject
    )
    
    process {
        if ($null -eq $InputObject) {
            return $null
        }
        
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @()
            foreach ($object in $InputObject) {
                $collection += ConvertTo-Hashtable -InputObject $object
            }
            return $collection
        }
        
        if ($InputObject -is [psobject]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hash
        }
        
        return $InputObject
    }
}

<#
.SYNOPSIS
    Gets the module version.
.DESCRIPTION
    Returns the version of the HomeLab.Core module.
.EXAMPLE
    $version = Get-ModuleVersion
.OUTPUTS
    String. Returns the module version as a string.
#>
function Get-ModuleVersion {
    [CmdletBinding()]
    param()
    
    try {
        $moduleInfo = Get-Module -Name HomeLab.Core -ErrorAction Stop
        return $moduleInfo.Version.ToString()
    }
    catch {
        # If the module is not loaded, try to get the version from the manifest
        $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\HomeLab.Core.psd1"
        if (Test-Path -Path $manifestPath) {
            $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction Stop
            return $manifest.ModuleVersion
        }
        
        return "Unknown"
    }
}
