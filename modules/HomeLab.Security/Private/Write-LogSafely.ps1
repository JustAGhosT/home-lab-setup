<#
.SYNOPSIS
    Safely writes log messages using available logging functions.
.DESCRIPTION
    Attempts to use Write-Log from HomeLab.Core if available, otherwise falls back to Write-Host.
.PARAMETER Message
    The message to log.
.PARAMETER Level
    The log level (INFO, WARNING, ERROR, DEBUG, etc.).
.EXAMPLE
    Write-LogSafely -Message "Certificate created" -Level INFO
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Write-LogSafely {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO"
    )
    
    # Check if Write-Log function exists
    if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message $Message -Level $Level
    }
    else {
        # Fallback to Write-Host with color coding
        $color = switch ($Level) {
            "ERROR"   { "Red" }
            "WARNING" { "Yellow" }
            "INFO"    { "White" }
            "DEBUG"   { "Gray" }
            default   { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}
