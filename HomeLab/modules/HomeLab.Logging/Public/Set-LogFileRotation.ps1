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
        Initialize-Logging -LogFilePath $LogFilePath
        
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
