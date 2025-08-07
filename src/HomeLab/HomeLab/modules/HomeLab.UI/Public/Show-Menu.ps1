<#
.SYNOPSIS
    Displays a menu and returns the user's selection.
.DESCRIPTION
    Displays a formatted menu with the provided title and menu items,
    and returns the user's selection. Supports customizable formatting,
    input validation, and multiple navigation options.
.PARAMETER Title
    The title of the menu.
.PARAMETER MenuItems
    A hashtable containing the menu items, where the key is the menu item number
    and the value is the menu item text or a hashtable with Text and Color properties.
.PARAMETER ReturnToMain
    If specified, adds a "Return to Main Menu" option with key "M".
.PARAMETER ExitOption
    Specifies the key for the exit/return option (default is "Q" for quit).
.PARAMETER ExitText
    Text to display for the exit option (default is "Quit" or "Return to Main Menu" if ReturnToMain is specified).
.PARAMETER ShowProgress
    If specified, shows a progress bar when loading the menu.
.PARAMETER DefaultOption
    Specifies the default option that will be selected if the user presses Enter without a selection.
.PARAMETER TitleColor
    The color to use for the menu title (default is Cyan).
.PARAMETER BorderChar
    Character to use for menu borders (default is "-").
.PARAMETER ValidateInput
    If specified, validates user input against available options and prompts again if invalid.
.PARAMETER ShowStatus
    Optional status message to display at the bottom of the menu.
.PARAMETER StatusColor
    Color for the status message (default is Yellow).
.PARAMETER ShowHelp
    If specified, adds a help option to the menu with key "?".
.EXAMPLE
    $menuItems = @{
        "1" = "Option 1"
        "2" = "Option 2"
        "3" = @{Text = "Important Option"; Color = "Red"}
    }
    $selection = Show-Menu -Title "Main Menu" -MenuItems $menuItems -DefaultOption "1" -ValidateInput
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
    Version: 1.0.2
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
        [string]$BorderChar = "-",
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateInput,
        
        [Parameter(Mandatory = $false)]
        [string]$ShowStatus,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$StatusColor = [System.ConsoleColor]::Yellow,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowHelp
    )
    
    if ($ShowProgress) {
        # Show a quick progress bar when loading the menu.
        for ($i = 0; $i -le 100; $i += 10) {
            Write-Progress -Activity "Loading Menu" -Status "Please wait..." -PercentComplete $i
            Start-Sleep -Milliseconds 50
        }
        Write-Progress -Activity "Loading Menu" -Completed
    }
    
    # Clear the screen.
    Clear-Host
    
    # Calculate border width based on title and menu items.
    $maxLength = $Title.Length
    foreach ($item in $MenuItems.Values) {
        $itemText = if ($item -is [hashtable]) { $item.Text } else { $item }
        $maxLength = [Math]::Max($maxLength, $itemText.Length + 6)  # +6 for "  [X] " prefix
    }
    $borderWidth = [Math]::Min([Math]::Max(40, $maxLength + 4), $Host.UI.RawUI.WindowSize.Width - 4)
    
    # Display the title with border.
    $border = $BorderChar * $borderWidth
    Write-Host "`n$border" -ForegroundColor $TitleColor
    $paddedTitle = " $Title "
    $leftPadding = [Math]::Floor(($borderWidth - $paddedTitle.Length) / 2)
    $rightPadding = $borderWidth - $paddedTitle.Length - $leftPadding
    $titleLine = ($BorderChar * $leftPadding) + $paddedTitle + ($BorderChar * $rightPadding)
    Write-Host $titleLine -ForegroundColor $TitleColor
    Write-Host "$border`n" -ForegroundColor $TitleColor
    
    # Create a sorted list of keys to avoid modifying the collection during enumeration.
    $sortedKeys = @($MenuItems.Keys | Sort-Object)
    
    # Display menu items.
    $validOptions = @()
    foreach ($key in $sortedKeys) {
        $validOptions += $key
        $item = $MenuItems[$key]
        if ($item -is [hashtable]) {
            $text = $item.Text
            $color = if ($item.ContainsKey('Color')) { $item.Color } else { 'White' }
        } else {
            $text = $item
            $color = 'White'
        }
        $prefix = if ($key -eq $DefaultOption) { "  [$key]* " } else { "  [$key] " }
        Write-Host "$prefix$text" -ForegroundColor $color
    }
    
    # Add navigation options.
    $navigationOptions = @()
    if ($ShowHelp) {
        Write-Host "`n  [?] Help" -ForegroundColor Yellow
        $validOptions += '?'
        $navigationOptions += '?'
    }
    
    # Determine exit/return text.
    if (-not $ExitText) {
        $ExitText = if ($ReturnToMain) { "Return to Main Menu" } else { "Exit" }
    }
    Write-Host "  [$ExitOption] $ExitText" -ForegroundColor Yellow
    $validOptions += $ExitOption
    $navigationOptions += $ExitOption
    
    # Show status if provided.
    if ($ShowStatus) {
        Write-Host "`n$($BorderChar * 20)" -ForegroundColor $StatusColor
        Write-Host $ShowStatus -ForegroundColor $StatusColor
        Write-Host "$($BorderChar * 20)" -ForegroundColor $StatusColor
    }
    
    # Show default option hint if provided.
    if ($DefaultOption) {
        Write-Host "`n* Default option (press Enter to select)" -ForegroundColor DarkGray
    }
    
    # Get user choice with validation if requested.
    $choice = $null
    do {
        Write-Host "`nSelect an option: " -ForegroundColor Cyan -NoNewline
        $userInput = Read-Host
        # Use default option if input is empty and default is provided.
        if ([string]::IsNullOrEmpty($userInput) -and $DefaultOption) {
            $choice = $DefaultOption
            break
        }
        $choice = $userInput.Trim()
        $isValid = -not $ValidateInput -or ($validOptions -contains $choice)
        if (-not $isValid) {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    } while (-not $isValid)
    
    # Return a PSCustomObject instead of a hashtable to ensure compatibility with Get-Member checks
    return [PSCustomObject]@{
        Choice = $choice
        IsNavigationOption = ($navigationOptions -contains $choice)
        IsExit = ($choice -eq $ExitOption)
        IsHelp = ($ShowHelp -and $choice -eq '?')
        RawInput = $userInput
    }
}
