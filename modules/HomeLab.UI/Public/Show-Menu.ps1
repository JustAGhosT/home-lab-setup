<#
.SYNOPSIS
    Displays a menu and returns the user's selection.
.DESCRIPTION
    Displays a formatted menu with the provided title and menu items,
    and returns the user's selection.
.PARAMETER Title
    The title of the menu.
.PARAMETER MenuItems
    A hashtable containing the menu items, where the key is the menu item number
    and the value is the menu item text.
.PARAMETER ExitOption
    The option number for exiting the menu (default is "0").
.EXAMPLE
    $menuItems = @{
        "1" = "Option 1"
        "2" = "Option 2"
    }
    $selection = Show-Menu -Title "Main Menu" -MenuItems $menuItems
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$MenuItems,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnToMain,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    if ($ShowProgress) {
        # Show a quick progress bar when loading the menu
        for ($i = 0; $i -le 100; $i += 10) {
            Show-ProgressBar -PercentComplete $i -Activity "Loading Menu" -Status "Please wait..." -Width 30
            Start-Sleep -Milliseconds 50  # Quick animation
        }
    }
    
    # Clear the screen
    Clear-Host
    
    # Display the title
    Write-ColorOutput "`n$Title`n" -ForegroundColor Cyan
    
    # Display menu items
    foreach ($key in $MenuItems.Keys | Sort-Object) {
        Write-ColorOutput "  [$key] $($MenuItems[$key])" -ForegroundColor White
    }
    
    # Add return to main menu option if requested
    if ($ReturnToMain) {
        Write-ColorOutput "`n  [M] Return to Main Menu" -ForegroundColor Yellow
        Write-ColorOutput "  [Q] Quit" -ForegroundColor Yellow
    }
    else {
        Write-ColorOutput "`n  [Q] Quit" -ForegroundColor Yellow
    }
    
    # Get user choice
    Write-ColorOutput "`nSelect an option: " -ForegroundColor Cyan -NoNewLine
    $choice = Read-Host
    
    return $choice
}
