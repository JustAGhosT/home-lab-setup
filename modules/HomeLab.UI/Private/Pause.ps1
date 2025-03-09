<#
.SYNOPSIS
    Pauses execution and waits for user input
.DESCRIPTION
    Displays a message and waits for the user to press a key before continuing
.PARAMETER Message
    The message to display (defaults to "Press any key to continue...")
.EXAMPLE
    Pause
.EXAMPLE
    Pause -Message "Press any key to return to the main menu..."
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Pause-ForUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Message = "Press any key to continue..."
    )
    
    Write-ColorOutput $Message -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}
