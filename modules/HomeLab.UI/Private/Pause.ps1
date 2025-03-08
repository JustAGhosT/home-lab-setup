<#
.SYNOPSIS
    Pauses execution until the user presses a key.
.DESCRIPTION
    Displays a message and waits for the user to press a key before continuing.
.EXAMPLE
    Pause
.EXAMPLE
    Pause -Message "Press any key to return to the menu..."
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Pause {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Message = "Press any key to continue..."
    )
    
    Write-ColorOutput "`n$Message" -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
