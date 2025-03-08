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
    Date: March 6, 2025
#>

function Initialize-LogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
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

function Set-LogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$ConsoleLevel = 'Info',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$FileLevel = 'Info'
    )
    
    # Define log level priorities
    $logLevelPriority = @{
        'Info'    = 0
        'Success' = 1
        'Warning' = 2
        'Error'   = 3
    }
    
    # Store the log levels in the global configuration
    $Global:Config.LogLevels = @{
        Console = $ConsoleLevel
        File    = $FileLevel
        ConsolePriority = $logLevelPriority[$ConsoleLevel]
        FilePriority    = $logLevelPriority[$FileLevel]
    }
    
    Write-Log -Message "Log levels set - Console: $ConsoleLevel, File: $FileLevel" -Level Info -Force
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
        [switch]$NoLog,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Define default colors for log levels.
    $defaultColors = @{
        'Info'    = 'White'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Success' = 'Green'
    }
    
    # Define log level priorities if not already defined
    if (-not $Global:Config.LogLevels) {
        $Global:Config.LogLevels = @{
            Console = 'Info'
            File    = 'Info'
            ConsolePriority = 0  # Info
            FilePriority    = 0  # Info
        }
    }
    
    $logLevelPriority = @{
        'Info'    = 0
        'Success' = 1
        'Warning' = 2
        'Error'   = 3
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
    
    # Check if we should write to console based on log level priority
    $writeToConsole = $Force -or (-not $NoConsole -and ($logLevelPriority[$Level] -ge $Global:Config.LogLevels.ConsolePriority))
    
    # Check if we should write to log file based on log level priority
    $writeToFile = $Force -or (-not $NoLog -and ($logLevelPriority[$Level] -ge $Global:Config.LogLevels.FilePriority))
    
    # Write to log file if logging is not suppressed and meets the minimum level.
    if ($writeToFile) {
        # Create the directory if it doesn't exist.
        $logDir = Split-Path -Parent $LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logMessage | Out-File -FilePath $LogFile -Append
    }
    
    # Write to console if not suppressed and meets the minimum level.
    if ($writeToConsole) {
        Write-Host $logMessage -ForegroundColor $Color
        [Console]::Out.Flush()
    }
}

function Set-LogFileRotation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $Global:Config.LogFile,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSizeMB = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$KeepCount = 5
    )
    
    # Check if the log file exists
    if (-not (Test-Path -Path $LogFilePath)) {
        Write-Host "Log file does not exist at $LogFilePath" -ForegroundColor Yellow
        return
    }
    
    # Get the file info
    $logFile = Get-Item -Path $LogFilePath
    
    # Check if the file size exceeds the maximum size
    if ($logFile.Length -gt ($MaxSizeMB * 1MB)) {
        $logDir = Split-Path -Path $LogFilePath -Parent
        $logFileName = Split-Path -Path $LogFilePath -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $rotatedLogPath = Join-Path -Path $logDir -ChildPath "$($logFileName).$timestamp"
        
        # Rename the current log file
        Rename-Item -Path $LogFilePath -NewName $rotatedLogPath
        
        # Create a new log file
        Initialize-LogFile -LogFilePath $LogFilePath
        
        # Write a message to the new log file
        Write-Log -Message "Log file rotated. Previous log: $rotatedLogPath" -Level Info
        
        # Clean up old log files if needed
        $rotatedLogs = Get-ChildItem -Path $logDir -Filter "$($logFileName).*" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $KeepCount
        
        if ($rotatedLogs) {
            foreach ($oldLog in $rotatedLogs) {
                Remove-Item -Path $oldLog.FullName -Force
                Write-Log -Message "Removed old log file: $($oldLog.Name)" -Level Info -NoConsole
            }
        }
        
        return $true
    }
    
    return $false
}

function Get-LogEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $Global:Config.LogFile,
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndTime,
        
        [Parameter(Mandatory = $false)]
        [int]$Tail
    )
    
    # Check if the log file exists
    if (-not (Test-Path -Path $LogFilePath)) {
        Write-Host "Log file does not exist at $LogFilePath" -ForegroundColor Yellow
        return @()
    }
    
    # Read the log file
    $logContent = Get-Content -Path $LogFilePath
    
    # Parse log entries
    $logEntries = @()
    foreach ($line in $logContent) {
        # Skip header lines and empty lines
        if ($line -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] \[(\w+)\] (.+)$') {
            $timestamp = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
            $entryLevel = $matches[2]
            $message = $matches[3]
            
            $logEntries += [PSCustomObject]@{
                Timestamp = $timestamp
                Level = $entryLevel
                Message = $message
                OriginalLine = $line
            }
        }
    }
    
    # Apply filters
    if ($Pattern) {
        $logEntries = $logEntries | Where-Object { $_.Message -match $Pattern -or $_.OriginalLine -match $Pattern }
    }
    
    if ($Level) {
        $logEntries = $logEntries | Where-Object { $_.Level -eq $Level }
    }
    
    if ($StartTime) {
        $logEntries = $logEntries | Where-Object { $_.Timestamp -ge $StartTime }
    }
    
    if ($EndTime) {
        $logEntries = $logEntries | Where-Object { $_.Timestamp -le $EndTime }
    }
    
    # Apply tail if specified
    if ($Tail -gt 0) {
        $logEntries = $logEntries | Select-Object -Last $Tail
    }
    
    return $logEntries
}

function Get-LogPath {
    [CmdletBinding()]
    param()
    
    return $Global:Config.LogFile
}

function Set-LogPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Initialize
    )
    
    # Update the log file path in the global configuration
    $Global:Config.LogFile = $Path
    
    # Initialize the new log file if requested
    if ($Initialize) {
        Initialize-LogFile -LogFilePath $Path
    }
    
    Write-Log -Message "Log path updated to $Path" -Level Info
}
