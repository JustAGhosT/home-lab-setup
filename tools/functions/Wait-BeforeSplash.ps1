<#
.SYNOPSIS
    Pauses execution for a specified time or until a key is pressed
.DESCRIPTION
    Displays a message and waits for either a key press or a specified timeout
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Wait-BeforeSplash {
    [CmdletBinding()]
    param(
        [ValidateRange(0,60)]
        [int]$Seconds = 2
    )
    # Check if we're in an interactive host
    if (-not ($Host.UI -and $Host.UI.RawUI)) {
        Start-Sleep -Seconds $Seconds
        return
    }
    
    Write-Host "Press any key to continue, or wait $Seconds seconds..."
    
    # We can wait for either a key press or for $Seconds to elapse
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while (!$Host.UI.RawUI.KeyAvailable -and $stopwatch.Elapsed.TotalSeconds -lt $Seconds) {
        Start-Sleep -Milliseconds 200
    }
    
    # If a key was pressed, consume it
    if ($Host.UI.RawUI.KeyAvailable) {
        [void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Export the function
Export-ModuleMember -Function Wait-BeforeSplash
