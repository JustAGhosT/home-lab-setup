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
#>
function Show-Menu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$MenuItems,
        
        [Parameter(Mandatory = $false)]
        [string]$ExitOption = "0"
    )
    
    Clear-Host
    
    # Build and display title bar
    $titleBar = "═" * ($Title.Length + 10)
    Write-Host "╔$titleBar╗" -ForegroundColor Blue
    Write-Host "║    $Title    ║" -ForegroundColor Blue
    Write-Host "╚$titleBar╝" -ForegroundColor Blue
    Write-Host ""
    
    # Display menu items in sorted order of keys
    foreach ($key in $MenuItems.Keys | Sort-Object) {
        Write-Host "$key. $($MenuItems[$key])" -ForegroundColor Green
    }
    
    # Display exit option
    Write-Host ""
    Write-Host "$ExitOption. Exit" -ForegroundColor Yellow
    Write-Host ""
    
    # Prompt for and return user selection
    $selection = Read-Host "Select an option"
    return $selection
}

Export-ModuleMember -Function Show-Menu
