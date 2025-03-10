function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info','Warning','Error','Success', 'Debug', 'Verbose', IgnoreCase = $true)]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [string]$Color,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $script:LogFile, # Use script-level variable as fallback
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoLog,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Define default colors for log levels
    $defaultColors = @{
        'Verbose' = 'Gray'
        'Debug'   = 'Cyan'
        'Info'    = 'White'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    # Define log level priorities
    $logLevelPriority = @{
        'Verbose' = -2
        'Debug'   = -1
        'Info'    = 0
        'Success' = 1
        'Warning' = 2
        'Error'   = 3
    }
    
    # Use provided color if any; otherwise default based on log level
    if (-not $Color) {
        $Color = $defaultColors[$Level]
    }
    
    # Use the provided LogFile if available; otherwise use the one in global config
    # Add fallback to script-level variable if global config is not available
    if (-not $LogFile) {
        if ($Global:Config -and $Global:Config.LogFile) {
            $LogFile = $Global:Config.LogFile
        } elseif ($script:LogFile) {
            $LogFile = $script:LogFile
        } else {
            # Ultimate fallback - create a log in the current directory
            $LogFile = Join-Path -Path $PSScriptRoot -ChildPath "logs\homelab_$(Get-Date -Format 'yyyyMMdd').log"
        }
    }
    
    # Format the timestamp and construct the log message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Default log levels if config is not available
    $defaultLogLevel = 'Info'
    $consoleLogLevel = $defaultLogLevel
    $fileLogLevel = $defaultLogLevel
    
    # Try to get log levels from config with proper error handling
    if ($Global:Config -and $Global:Config.Logging) {
        # Get console log level from config with fallbacks
        if ($Global:Config.Logging.ConsoleLogLevel) { 
            $consoleLogLevel = $Global:Config.Logging.ConsoleLogLevel 
        } elseif ($Global:Config.Logging.DefaultLogLevel) { 
            $consoleLogLevel = $Global:Config.Logging.DefaultLogLevel 
        }
        
        # Get file log level from config with fallbacks
        if ($Global:Config.Logging.FileLogLevel) { 
            $fileLogLevel = $Global:Config.Logging.FileLogLevel 
        } elseif ($Global:Config.Logging.DefaultLogLevel) { 
            $fileLogLevel = $Global:Config.Logging.DefaultLogLevel 
        }
        
        # Check if file logging is enabled in config
        $fileLoggingEnabled = $Force -or ($Global:Config.Logging.EnableFileLogging -eq $true)
        
        # Check if console logging is enabled in config
        $consoleLoggingEnabled = $Force -or ($Global:Config.Logging.EnableConsoleLogging -eq $true)
    } else {
        # Default to enabled if config is not available
        $fileLoggingEnabled = $Force -or $true
        $consoleLoggingEnabled = $Force -or $true
    }
    
    # Check if we should write to console based on log level priority and settings
    $writeToConsole = $consoleLoggingEnabled -and (-not $NoConsole) -and 
                     ($logLevelPriority[$Level] -ge $logLevelPriority[$consoleLogLevel])
    
    # Check if we should write to log file based on log level priority and settings
    $writeToFile = $fileLoggingEnabled -and (-not $NoLog) -and 
                  ($logLevelPriority[$Level] -ge $logLevelPriority[$fileLogLevel])
    
    # Write to log file if logging is not suppressed and meets the minimum level
    if ($writeToFile -and $LogFile) {
        # Create the directory if it doesn't exist
        $logDir = Split-Path -Parent $LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        try {
            $logMessage | Out-File -FilePath $LogFile -Append -ErrorAction Stop
        }
        catch {
            # If we can't write to the log file, at least output an error to the console
            Write-Host "ERROR: Failed to write to log file $LogFile : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Write to console if not suppressed and meets the minimum level
    if ($writeToConsole) {
        Write-Host $logMessage -ForegroundColor $Color
        [Console]::Out.Flush()
    }
}
