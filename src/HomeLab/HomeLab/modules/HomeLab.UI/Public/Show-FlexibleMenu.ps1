<#
.SYNOPSIS
    Flexible menu system that handles different input formats.
.DESCRIPTION
    This function wraps the standard Show-Menu function but can handle both
    hashtable and array inputs, converting arrays to hashtables as needed.
.PARAMETER Title
    The title of the menu.
.PARAMETER MenuItems
    Menu items in either hashtable or array format.
.PARAMETER ReturnToMain
    If specified, adds a "Return to Main Menu" option with key "M".
.PARAMETER ExitOption
    Specifies the key for the exit/return option (default is "0").
.PARAMETER ExitText
    Text to display for the exit option (default is "Quit" or "Return to Main Menu" if ReturnToMain is specified).
.PARAMETER ShowProgress
    If specified, shows a progress bar when loading the menu.
.PARAMETER DefaultOption
    Specifies the default option that will be selected if the user presses Enter without a selection.
.PARAMETER TitleColor
    The color to use for the menu title (default is Cyan).
.PARAMETER ValidateInput
    If specified, validates user input against available options and prompts again if invalid.
.PARAMETER ShowStatus
    Optional status message to display at the bottom of the menu.
.EXAMPLE
    # Array input example
    $items = @(
        @{ Name = "Option 1"; Command = "Cmd1" },
        @{ Name = "Option 2"; Command = "Cmd2" }
    )
    Show-FlexibleMenu -Title "My Menu" -MenuItems $items -ExitOption "0"
.EXAMPLE
    # Hashtable input example
    $items = @{
        "1" = "Option 1"
        "2" = "Option 2"
    }
    Show-FlexibleMenu -Title "My Menu" -MenuItems $items -ExitOption "0"
.NOTES
    Author: HomeLab Support
    Date: August 3, 2025
#>
function Show-FlexibleMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [object]$MenuItems,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnToMain,
        
        [Parameter(Mandatory = $false)]
        [string]$ExitOption = "0",
        
        [Parameter(Mandatory = $false)]
        [string]$ExitText,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultOption,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$TitleColor = [System.ConsoleColor]::Cyan,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateInput,
        
        [Parameter(Mandatory = $false)]
        [string]$ShowStatus
    )
    
    # Check if MenuItems is already a hashtable
    if ($MenuItems -is [hashtable]) {
        $formattedMenuItems = $MenuItems
    }
    # If it's an array, convert it to a hashtable
    elseif ($MenuItems -is [array]) {
        $formattedMenuItems = @{}
        
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $item = $MenuItems[$i]
            $key = ($i + 1).ToString()
            
            # Handle item format based on its type
            if ($item -is [hashtable] -and $item.ContainsKey('Name')) {
                # If it has a Name property, use that
                $formattedMenuItems[$key] = $item.Name
            }
            elseif ($item -is [string]) {
                # If it's a string, use directly
                $formattedMenuItems[$key] = $item
            }
            elseif ($item -is [PSCustomObject]) {
                # If it's a PSCustomObject, get Name property if exists
                if (Get-Member -InputObject $item -Name "Name" -MemberType Properties) {
                    $formattedMenuItems[$key] = $item.Name
                }
                else {
                    # Default to string representation
                    $formattedMenuItems[$key] = $item.ToString()
                }
            }
            else {
                # Default fallback
                $formattedMenuItems[$key] = "Option $key"
            }
        }
    }
    else {
        throw "MenuItems must be either a hashtable or an array"
    }
    
    # Now call the standard Show-Menu with the properly formatted hashtable
    $params = @{
        Title = $Title
        MenuItems = $formattedMenuItems
        ExitOption = $ExitOption
        ShowProgress = $ShowProgress
        ValidateInput = $ValidateInput
    }
    
    if ($ReturnToMain) {
        $params.ReturnToMain = $true
    }
    
    if ($DefaultOption) {
        $params.DefaultOption = $DefaultOption
    }
    
    if ($ExitText) {
        $params.ExitText = $ExitText
    }
    
    if ($ShowStatus) {
        $params.ShowStatus = $ShowStatus
    }
    
    # Call the standard Show-Menu function
    try {
        $result = Show-Menu @params
        return $result
    }
    catch {
        Write-Host "Error in Show-FlexibleMenu: $($_.Exception.Message)" -ForegroundColor Red
        
        # Return a simple object to avoid breaking the calling code
        return [PSCustomObject]@{
            Choice = $ExitOption
            IsNavigationOption = $true
            IsExit = $true
            IsHelp = $false
            RawInput = ""
            Error = $true
            ErrorMessage = $_.Exception.Message
        }
    }
}