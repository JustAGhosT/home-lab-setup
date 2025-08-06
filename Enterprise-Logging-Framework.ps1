# Enterprise PowerShell Logging Framework
# Production-Ready Solution for HomeLab Infrastructure
# Replaces Write-Host usage and provides enterprise-grade logging

<#
.SYNOPSIS
    Enterprise PowerShell Logging Framework
.DESCRIPTION
    Production-ready logging solution that replaces Write-Host usage and provides
    comprehensive logging capabilities for PowerShell automation and CI/CD pipelines.
    
    Features:
    - Structured logging with multiple output formats
    - Log rotation and retention management
    - Performance monitoring and metrics
    - CI/CD pipeline compatibility
    - Security audit trail
    - Error correlation and troubleshooting
    
.PARAMETER LogPath
    Base directory for log files
.PARAMETER LogLevel
    Minimum log level to process (Verbose, Debug, Info, Warning, Error, Critical)
.PARAMETER EnableConsoleOutput
    Whether to output to console (default: true)
.PARAMETER EnableFileOutput
    Whether to output to file (default: true)
.PARAMETER EnableEventLog
    Whether to write to Windows Event Log (default: false)
.PARAMETER MaxLogFileSizeMB
    Maximum log file size before rotation (default: 100MB)
.PARAMETER MaxLogFiles
    Maximum number of log files to retain (default: 10)
.EXAMPLE
    Initialize-EnterpriseLogging -LogPath "C:\Logs\HomeLab" -LogLevel Info
.NOTES
    Author: Enterprise PowerShell Team
    Version: 2.0.0
    Date: 2025-01-27
#>

#region Module Variables
$script:LogConfig = @{
    LogPath             = $env:TEMP
    LogLevel            = 'Info'
    EnableConsoleOutput = $true
    EnableFileOutput    = $true
    EnableEventLog      = $false
    MaxLogFileSizeMB    = 100
    MaxLogFiles         = 10
    LogFormat           = 'Structured'
    CorrelationId       = [System.Guid]::NewGuid().ToString()
    StartTime           = Get-Date
    PerformanceMetrics  = @{}
}

$script:LogLevels = @{
    'Verbose'  = 0
    'Debug'    = 1
    'Info'     = 2
    'Warning'  = 3
    'Error'    = 4
    'Critical' = 5
}

$script:ConsoleColors = @{
    'Verbose'  = 'Gray'
    'Debug'    = 'Cyan'
    'Info'     = 'White'
    'Warning'  = 'Yellow'
    'Error'    = 'Red'
    'Critical' = 'Magenta'
    'Success'  = 'Green'
}
#endregion

#region Core Logging Functions

<#
.SYNOPSIS
    Initializes the enterprise logging framework
.DESCRIPTION
    Sets up logging configuration and creates necessary directories
#>
function Initialize-EnterpriseLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Verbose', 'Debug', 'Info', 'Warning', 'Error', 'Critical')]
        [string]$LogLevel = 'Info',
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableConsoleOutput = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableFileOutput = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableEventLog = $false,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLogFileSizeMB = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 10
    )
    
    try {
        # Update configuration
        $script:LogConfig.LogPath = $LogPath
        $script:LogConfig.LogLevel = $LogLevel
        $script:LogConfig.EnableConsoleOutput = $EnableConsoleOutput
        $script:LogConfig.EnableFileOutput = $EnableFileOutput
        $script:LogConfig.EnableEventLog = $EnableEventLog
        $script:LogConfig.MaxLogFileSizeMB = $MaxLogFileSizeMB
        $script:LogConfig.MaxLogFiles = $MaxLogFiles
        $script:LogConfig.CorrelationId = [System.Guid]::NewGuid().ToString()
        $script:LogConfig.StartTime = Get-Date
        
        # Create log directory if it doesn't exist
        if ($EnableFileOutput -and -not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        # Initialize performance metrics
        $script:LogConfig.PerformanceMetrics = @{
            'TotalLogs' = 0
            'Errors'    = 0
            'Warnings'  = 0
            'StartTime' = Get-Date
        }
        
        # Log initialization
        Write-EnterpriseLog -Message "Enterprise logging framework initialized" -Level Info -Category 'System'
        Write-EnterpriseLog -Message "Log path: $LogPath" -Level Debug -Category 'System'
        Write-EnterpriseLog -Message "Log level: $LogLevel" -Level Debug -Category 'System'
        Write-EnterpriseLog -Message "Correlation ID: $($script:LogConfig.CorrelationId)" -Level Debug -Category 'System'
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize enterprise logging: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Writes a log entry using the enterprise logging framework
.DESCRIPTION
    Main logging function that handles structured logging with multiple outputs
#>
function Write-EnterpriseLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Verbose', 'Debug', 'Info', 'Warning', 'Error', 'Critical', 'Success')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [string]$Category = 'General',
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{},
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoFile
    )
    
    try {
        # Check if logging is initialized
        if (-not $script:LogConfig) {
            Initialize-EnterpriseLogging
        }
        
        # Check log level filter
        if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogConfig.LogLevel]) {
            return
        }
        
        # Build log entry
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = @{
            Timestamp     = $timestamp
            Level         = $Level
            Category      = $Category
            Message       = $Message
            CorrelationId = $script:LogConfig.CorrelationId
            Properties    = $Properties
            ProcessId     = $PID
            ThreadId      = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        }
        
        # Add error details if provided
        if ($ErrorRecord) {
            $logEntry.Error = @{
                Exception        = $ErrorRecord.Exception.Message
                ScriptStackTrace = $ErrorRecord.ScriptStackTrace
                CategoryInfo     = $ErrorRecord.CategoryInfo.ToString()
            }
        }
        
        # Update performance metrics
        $script:LogConfig.PerformanceMetrics.TotalLogs++
        switch ($Level) {
            'Error' { $script:LogConfig.PerformanceMetrics.Errors++ }
            'Warning' { $script:LogConfig.PerformanceMetrics.Warnings++ }
        }
        
        # Console output
        if ($script:LogConfig.EnableConsoleOutput -and -not $NoConsole) {
            $consoleMessage = Format-ConsoleMessage -LogEntry $logEntry
            $color = $script:ConsoleColors[$Level]
            Write-Host $consoleMessage -ForegroundColor $color
        }
        
        # File output
        if ($script:LogConfig.EnableFileOutput -and -not $NoFile) {
            $fileMessage = Format-FileMessage -LogEntry $logEntry
            Write-LogToFile -Message $fileMessage
        }
        
        # Event Log output
        if ($script:LogConfig.EnableEventLog) {
            Write-LogToEventLog -LogEntry $logEntry
        }
    }
    catch {
        # Fallback to basic logging if enterprise logging fails
        Write-Host "[ERROR] Enterprise logging failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $script:ConsoleColors[$Level]
    }
}

<#
.SYNOPSIS
    Convenience function for success messages
#>
function Write-SuccessLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = 'General',
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{}
    )
    
    Write-EnterpriseLog -Message $Message -Level Success -Category $Category -Properties $Properties
}

<#
.SYNOPSIS
    Convenience function for error messages
#>
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = 'Error',
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{}
    )
    
    Write-EnterpriseLog -Message $Message -Level Error -Category $Category -Properties $Properties -ErrorRecord $ErrorRecord
}

<#
.SYNOPSIS
    Convenience function for warning messages
#>
function Write-WarningLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = 'Warning',
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{}
    )
    
    Write-EnterpriseLog -Message $Message -Level Warning -Category $Category -Properties $Properties
}

<#
.SYNOPSIS
    Convenience function for info messages
#>
function Write-InfoLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = 'Info',
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{}
    )
    
    Write-EnterpriseLog -Message $Message -Level Info -Category $Category -Properties $Properties
}

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Formats log entry for console output
#>
function Format-ConsoleMessage {
    param([hashtable]$LogEntry)
    
    $timestamp = $LogEntry.Timestamp
    $level = $LogEntry.Level.ToUpper()
    $category = $LogEntry.Category
    $message = $LogEntry.Message
    
    return "[$timestamp] [$level] [$category] $message"
}

<#
.SYNOPSIS
    Formats log entry for file output (JSON format)
#>
function Format-FileMessage {
    param([hashtable]$LogEntry)
    
    return $LogEntry | ConvertTo-Json -Compress
}

<#
.SYNOPSIS
    Writes log entry to file with rotation
#>
function Write-LogToFile {
    param([string]$Message)
    
    try {
        $logFile = Join-Path $script:LogConfig.LogPath "HomeLab-$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Check file size and rotate if needed
        if (Test-Path $logFile) {
            $fileSize = (Get-Item $logFile).Length / 1MB
            if ($fileSize -gt $script:LogConfig.MaxLogFileSizeMB) {
                Rotate-LogFile -LogFile $logFile
            }
        }
        
        # Write to file
        $Message | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Rotates log files when they exceed size limit
#>
function Rotate-LogFile {
    param([string]$LogFile)
    
    try {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($LogFile)
        $extension = [System.IO.Path]::GetExtension($LogFile)
        $directory = [System.IO.Path]::GetDirectoryName($LogFile)
        
        # Create backup filename with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = Join-Path $directory "$baseName-$timestamp$extension"
        
        # Move current file to backup
        Move-Item -Path $LogFile -Destination $backupFile -Force
        
        # Clean up old log files
        $oldFiles = Get-ChildItem -Path $directory -Filter "$baseName-*$extension" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -Skip $script:LogConfig.MaxLogFiles
        
        foreach ($file in $oldFiles) {
            Remove-Item -Path $file.FullName -Force
        }
    }
    catch {
        Write-Host "Failed to rotate log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Writes log entry to Windows Event Log
#>
function Write-LogToEventLog {
    param([hashtable]$LogEntry)
    
    try {
        $eventSource = "HomeLab-EnterpriseLogging"
        $eventId = switch ($LogEntry.Level) {
            'Critical' { 1 }
            'Error' { 2 }
            'Warning' { 3 }
            'Info' { 4 }
            default { 5 }
        }
        
        $eventType = switch ($LogEntry.Level) {
            'Critical' { 'Error' }
            'Error' { 'Error' }
            'Warning' { 'Warning' }
            default { 'Information' }
        }
        
        $message = "[$($LogEntry.Category)] $($LogEntry.Message)"
        
        # Create event source if it doesn't exist
        if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
            [System.Diagnostics.EventLog]::CreateEventSource($eventSource, "Application")
        }
        
        # Write to event log
        [System.Diagnostics.EventLog]::WriteEntry($eventSource, $message, $eventType, $eventId)
    }
    catch {
        Write-Host "Failed to write to event log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Performance and Monitoring Functions

<#
.SYNOPSIS
    Gets logging performance metrics
#>
function Get-LoggingMetrics {
    [CmdletBinding()]
    param()
    
    if (-not $script:LogConfig) {
        return $null
    }
    
    $metrics = $script:LogConfig.PerformanceMetrics.Clone()
    $metrics.Uptime = (Get-Date) - $metrics.StartTime
    $metrics.LogRate = if ($metrics.Uptime.TotalSeconds -gt 0) { 
        $metrics.TotalLogs / $metrics.Uptime.TotalSeconds 
    }
    else { 0 }
    
    return $metrics
}

<#
.SYNOPSIS
    Gets log entries for analysis
#>
function Get-LogEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:LogConfig.LogPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxEntries = 1000
    )
    
    try {
        $logFiles = Get-ChildItem -Path $LogPath -Filter "HomeLab-*.log" | Sort-Object LastWriteTime -Descending
        
        $entries = @()
        foreach ($file in $logFiles) {
            $fileEntries = Get-Content -Path $file.FullName | 
            Where-Object { $_ -match '^\s*\{' } | 
            ForEach-Object { 
                try { $_ | ConvertFrom-Json } 
                catch { $null } 
            } |
            Where-Object { $_ -ne $null }
            
            $entries += $fileEntries
        }
        
        # Apply filters
        if ($Level) {
            $entries = $entries | Where-Object { $_.Level -eq $Level }
        }
        
        if ($Category) {
            $entries = $entries | Where-Object { $_.Category -eq $Category }
        }
        
        # Return limited results
        return $entries | Sort-Object Timestamp -Descending | Select-Object -First $MaxEntries
    }
    catch {
        Write-Error "Failed to retrieve log entries: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Exports logs for analysis or compliance
#>
function Export-Logs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV', 'XML')]
        [string]$Format = 'JSON',
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndDate
    )
    
    try {
        $entries = Get-LogEntries
        
        # Apply date filters
        if ($StartDate) {
            $entries = $entries | Where-Object { [datetime]::Parse($_.Timestamp) -ge $StartDate }
        }
        
        if ($EndDate) {
            $entries = $entries | Where-Object { [datetime]::Parse($_.Timestamp) -le $EndDate }
        }
        
        # Export based on format
        switch ($Format) {
            'JSON' {
                $entries | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'CSV' {
                $entries | Select-Object Timestamp, Level, Category, Message, CorrelationId | 
                Export-Csv -Path $OutputPath -NoTypeInformation
            }
            'XML' {
                $entries | Export-Clixml -Path $OutputPath
            }
        }
        
        Write-SuccessLog -Message "Logs exported to $OutputPath" -Category 'Export'
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to export logs: $($_.Exception.Message)" -Category 'Export'
        return $false
    }
}

#endregion

#region Migration Helper Functions

<#
.SYNOPSIS
    Migrates existing Write-Host usage to enterprise logging
#>
function Convert-WriteHostToEnterpriseLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content
        
        # Pattern to match Write-Host with color parameters
        $patterns = @(
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+(\w+)'
                Replacement = 'Write-EnterpriseLog -Message "$1" -Level $2'
            },
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+Green'
                Replacement = 'Write-SuccessLog -Message "$1"'
            },
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+Red'
                Replacement = 'Write-ErrorLog -Message "$1"'
            },
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+Yellow'
                Replacement = 'Write-WarningLog -Message "$1"'
            },
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"\s+-ForegroundColor\s+White'
                Replacement = 'Write-InfoLog -Message "$1"'
            },
            @{
                Pattern     = 'Write-Host\s+"([^"]+)"'
                Replacement = 'Write-InfoLog -Message "$1"'
            }
        )
        
        foreach ($pattern in $patterns) {
            $content = $content -replace $pattern.Pattern, $pattern.Replacement
        }
        
        if ($WhatIf) {
            Write-Host "Would convert $FilePath:" -ForegroundColor Yellow
            Write-Host "Changes: $(([regex]::Matches($originalContent, 'Write-Host')).Count) Write-Host calls found" -ForegroundColor Cyan
        }
        else {
            # Add import statement if not present
            if ($content -notmatch 'Import-Module.*Enterprise-Logging-Framework') {
                $importStatement = "# Import enterprise logging framework`nImport-Module `"$PSScriptRoot\Enterprise-Logging-Framework.ps1`"`n"
                $content = $importStatement + $content
            }
            
            # Backup original file
            $backupPath = "$FilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $FilePath -Destination $backupPath
            
            # Write converted content
            $content | Out-File -FilePath $FilePath -Encoding UTF8
            
            Write-SuccessLog -Message "Converted $FilePath to use enterprise logging" -Category 'Migration'
            Write-InfoLog -Message "Backup created at: $backupPath" -Category 'Migration'
        }
        
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to convert $FilePath : $($_.Exception.Message)" -Category 'Migration'
        return $false
    }
}

<#
.SYNOPSIS
    Batch converts multiple files to use enterprise logging
#>
function Convert-MultipleFilesToEnterpriseLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.ps1",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )
    
    try {
        $files = Get-ChildItem -Path $Directory -Filter $Filter -Recurse:$Recurse
        
        $results = @{
            Total     = $files.Count
            Converted = 0
            Failed    = 0
            Errors    = @()
        }
        
        foreach ($file in $files) {
            try {
                $success = Convert-WriteHostToEnterpriseLog -FilePath $file.FullName -WhatIf:$WhatIf
                if ($success) {
                    $results.Converted++
                }
                else {
                    $results.Failed++
                    $results.Errors += "Failed to convert: $($file.FullName)"
                }
            }
            catch {
                $results.Failed++
                $results.Errors += "Error converting $($file.FullName): $($_.Exception.Message)"
            }
        }
        
        # Report results
        Write-InfoLog -Message "Batch conversion completed" -Category 'Migration'
        Write-InfoLog -Message "Total files: $($results.Total)" -Category 'Migration'
        Write-InfoLog -Message "Converted: $($results.Converted)" -Category 'Migration'
        Write-InfoLog -Message "Failed: $($results.Failed)" -Category 'Migration'
        
        if ($results.Errors.Count -gt 0) {
            Write-WarningLog -Message "Conversion errors occurred" -Category 'Migration'
            foreach ($error in $results.Errors) {
                Write-WarningLog -Message $error -Category 'Migration'
            }
        }
        
        return $results
    }
    catch {
        Write-ErrorLog -Message "Batch conversion failed: $($_.Exception.Message)" -Category 'Migration'
        return $null
    }
}

#endregion

#region Module Export
# Export all public functions
Export-ModuleMember -Function @(
    'Initialize-EnterpriseLogging',
    'Write-EnterpriseLog',
    'Write-SuccessLog',
    'Write-ErrorLog',
    'Write-WarningLog',
    'Write-InfoLog',
    'Get-LoggingMetrics',
    'Get-LogEntries',
    'Export-Logs',
    'Convert-WriteHostToEnterpriseLog',
    'Convert-MultipleFilesToEnterpriseLog'
)

# Initialize logging when module is imported
Initialize-EnterpriseLogging
#endregion
