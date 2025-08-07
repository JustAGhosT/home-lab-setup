<#
.SYNOPSIS
    Validates and ensures an export path exists.
.DESCRIPTION
    Checks if the specified path exists and is writable, creating it if necessary.
.PARAMETER Path
    The path to validate and ensure.
.EXAMPLE
    if (Confirm-ExportPath -Path "C:\Certificates") { # Path is valid and writable }
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Confirm-ExportPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-LogSafely -Message "Created export directory: $Path" -Level INFO
        }
        catch {
            Write-LogSafely -Message "Failed to create export directory: $Path. Error: $_" -Level ERROR
            return $false
        }
    }
    
    # Test if we can write to this directory
    try {
        $testFile = Join-Path -Path $Path -ChildPath "write_test_$([Guid]::NewGuid().ToString()).tmp"
        [System.IO.File]::WriteAllText($testFile, "Test")
        Remove-Item -Path $testFile -Force
        return $true
    }
    catch {
        Write-LogSafely -Message "Export directory $Path is not writable. Error: $_" -Level ERROR
        return $false
    }
}
