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
