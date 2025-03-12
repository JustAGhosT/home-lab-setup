<#
.SYNOPSIS
    Writes an error log message
.DESCRIPTION
    Wrapper function for Write-Log that specifically logs messages with the Error level
.PARAMETER Message
    The message to log
.PARAMETER LogFilePath
    Optional path to the log file. If not specified, uses the current log file path
.EXAMPLE
    Write-ErrorLog -Message "Failed to connect to server: $($_.Exception.Message)"
.NOTES
    Part of HomeLab.Logging module
#>
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $script:LogPath
    )
    
    Write-Log -Message $Message -Level Error -LogFile $LogFilePath
}
