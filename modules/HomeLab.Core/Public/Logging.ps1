<#
.SYNOPSIS
    Logging Module for Home Lab Setup.
.DESCRIPTION
    Provides functions for initializing a log file and writing log entries.
    It uses the global configuration ($Global:Config) for environment details and
    supports writing messages with a timestamp and log level, both to the console and
    optionally to a log file.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function Initialize-LogFile {
    param (
        [string]$LogFilePath = $Global:Config.LogFile
    )
    
    # Ensure the log directory exists.
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Create the log file if it doesn't exist.
    if (-not (Test-Path -Path $LogFilePath)) {
        New-Item -ItemType File -Path $LogFilePath -Force | Out-Null
    }
    
    # Write a header to the log file using global configuration values.
    $header = @(
        "===== Home Lab Setup Log - $(Get-Date) =====",
        "Environment: $($Global:Config.env)",
        "Location: $($Global:Config.loc)",
        "Project: $($Global:Config.project)",
        "========================================"
    )
    Add-Content -Path $LogFilePath -Value $header
}

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [string]$Color,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoLog
    )
    
    # Define default colors for log levels.
    $defaultColors = @{
        'Info'    = 'White'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Success' = 'Green'
    }
    
    # Use provided color if any; otherwise default based on log level.
    if (-not $Color) {
        $Color = $defaultColors[$Level]
    }
    
    # Use the provided LogFile if available; otherwise use the one in global config.
    if (-not $LogFile) {
        $LogFile = $Global:Config.LogFile
    }
    
    # Format the timestamp and construct the log message.
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to log file if logging is not suppressed.
    if (-not $NoLog) {
        # Create the directory if it doesn't exist.
        $logDir = Split-Path -Parent $LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logMessage | Out-File -FilePath $LogFile -Append
    }
    
    # Write to console if not suppressed.
    if (-not $NoConsole) {
        Write-Host $logMessage -ForegroundColor $Color
        [Console]::Out.Flush()
    }
}

Export-ModuleMember -Function Initialize-LogFile, Write-Log
