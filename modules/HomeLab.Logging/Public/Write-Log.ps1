function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info','Warning','Error','Success', 'Debug', IgnoreCase = $true)]
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
        'Debug' = 'Cyan'
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
