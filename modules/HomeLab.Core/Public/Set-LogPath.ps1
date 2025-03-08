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
