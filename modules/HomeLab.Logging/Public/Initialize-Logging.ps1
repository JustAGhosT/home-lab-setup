<#
.SYNOPSIS
    Initializes a log file for the HomeLab application
.DESCRIPTION
    Creates or clears a log file at the specified path and writes an initial header entry.
    Sets the global log file path for other logging functions to use.
.PARAMETER LogFilePath
    The full path to the log file to initialize
.PARAMETER Append
    If specified, appends to an existing log file instead of creating a new one
.EXAMPLE
    Initialize-Logging -LogFilePath "C:\Logs\homelab.log"
    Creates or clears the log file at the specified path
.NOTES
    Part of the HomeLab.Core module
#>
function Initialize-Logging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "None")]
        [string]$LogLevel = "Info",
        
        [Parameter(Mandatory = $false)]
        [switch]$Append
    )
    
    # Store log path and level in script-level variables for other functions to use
    $script:LogFilePath = $LogFilePath
    $script:LogLevel = $LogLevel
    
    try {
        # Create directory if it doesn't exist
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Create or clear the log file
        if (-not $Append -or -not (Test-Path -Path $LogFilePath)) {
            # Create a new log file with header
            $header = @"
# HomeLab Log File
# Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Version: $($script:Version)
# Log Level: $LogLevel
# Environment: $($Global:Config.env),
# Location: $($Global:Config.loc),
# Project: $($Global:Config.project),
# -----------------------------------------------------

"@
            Set-Content -Path $LogFilePath -Value $header
        }
        else {
            # Append a session separator to existing log
            $separator = @"

# -----------------------------------------------------
# New Session Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Log Level: $LogLevel
# -----------------------------------------------------

"@
            Add-Content -Path $LogFilePath -Value $separator
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize log file: $_"
        return $false
    }
}

# Export the function
Export-ModuleMember -Function Initialize-Logging
