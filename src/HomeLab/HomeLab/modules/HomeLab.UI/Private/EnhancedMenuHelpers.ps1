<#
.SYNOPSIS
    Enhanced menu helper functions for HomeLab.UI module.
.DESCRIPTION
    Provides advanced menu capabilities including keyboard shortcuts, navigation memory, and search.
.NOTES
    Author: HomeLab Support
    Date: November 17, 2025
#>

# Module-level variable to store menu history
$script:MenuHistory = @()
$script:MenuHistoryMaxSize = 10

function Add-MenuHistory {
    <#
    .SYNOPSIS
        Adds a menu selection to history.
    .PARAMETER MenuName
        The name of the menu.
    .PARAMETER Selection
        The user's selection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MenuName,
        
        [Parameter(Mandatory = $true)]
        [string]$Selection
    )
    
    $entry = [PSCustomObject]@{
        MenuName = $MenuName
        Selection = $Selection
        Timestamp = Get-Date
    }
    
    $script:MenuHistory += $entry
    
    # Keep only the last N entries
    if ($script:MenuHistory.Count -gt $script:MenuHistoryMaxSize) {
        $script:MenuHistory = $script:MenuHistory[-$script:MenuHistoryMaxSize..-1]
    }
}

function Get-MenuHistory {
    <#
    .SYNOPSIS
        Retrieves menu history.
    .PARAMETER Last
        Number of last entries to retrieve.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Last = 5
    )
    
    if ($script:MenuHistory.Count -eq 0) {
        return @()
    }
    
    $count = [Math]::Min($Last, $script:MenuHistory.Count)
    return $script:MenuHistory[-$count..-1]
}

function Show-MenuHelp {
    <#
    .SYNOPSIS
        Displays help for menu navigation.
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    MENU NAVIGATION HELP                    " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "KEYBOARD SHORTCUTS:" -ForegroundColor Yellow
    Write-Host "  0       - Exit/Return to previous menu" -ForegroundColor White
    Write-Host "  ?       - Show this help" -ForegroundColor White
    Write-Host "  h       - Show recent history" -ForegroundColor White
    Write-Host "  /       - Search menu items (if supported)" -ForegroundColor White
    Write-Host "  Ctrl+C  - Emergency exit" -ForegroundColor White
    Write-Host ""
    Write-Host "NAVIGATION:" -ForegroundColor Yellow
    Write-Host "  • Enter the number of your choice and press Enter" -ForegroundColor White
    Write-Host "  • Some menus support default options (press Enter without typing)" -ForegroundColor White
    Write-Host "  • Look for the * symbol next to default options" -ForegroundColor White
    Write-Host ""
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "  • Menu colors indicate different types of actions" -ForegroundColor White
    Write-Host "    - Cyan/Blue: Navigation and deployment options" -ForegroundColor White
    Write-Host "    - Yellow: Return/back options" -ForegroundColor White
    Write-Host "    - Green: Success messages" -ForegroundColor White
    Write-Host "    - Red: Errors and warnings" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to return"
}

function Show-RecentHistory {
    <#
    .SYNOPSIS
        Displays recent menu navigation history.
    #>
    [CmdletBinding()]
    param()
    
    $history = Get-MenuHistory -Last 10
    
    if ($history.Count -eq 0) {
        Write-Host "No recent history available." -ForegroundColor Yellow
        return
    }
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                   RECENT MENU HISTORY                      " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $history | ForEach-Object {
        $timeAgo = (Get-Date) - $_.Timestamp
        $timeStr = if ($timeAgo.TotalMinutes -lt 1) {
            "Just now"
        } elseif ($timeAgo.TotalMinutes -lt 60) {
            "{0:N0} min ago" -f $timeAgo.TotalMinutes
        } else {
            "{0:N0} hr ago" -f $timeAgo.TotalHours
        }
        
        Write-Host "  [$timeStr] " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($_.MenuName): " -ForegroundColor Cyan -NoNewline
        Write-Host "$($_.Selection)" -ForegroundColor White
    }
    
    Write-Host ""
    Read-Host "Press Enter to return"
}

function Get-KeyboardShortcut {
    <#
    .SYNOPSIS
        Processes keyboard shortcuts for menu navigation.
    .PARAMETER Input
        The user's input string.
    .PARAMETER MenuName
        The name of the current menu.
    .OUTPUTS
        PSCustomObject with Action and Continue properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Input,
        
        [Parameter(Mandatory = $false)]
        [string]$MenuName = "Menu"
    )
    
    switch ($Input.Trim()) {
        "?" {
            Show-MenuHelp
            return [PSCustomObject]@{
                Action = "Help"
                Continue = $true
            }
        }
        "h" {
            Show-RecentHistory
            return [PSCustomObject]@{
                Action = "History"
                Continue = $true
            }
        }
        "/" {
            return [PSCustomObject]@{
                Action = "Search"
                Continue = $true
            }
        }
        default {
            return [PSCustomObject]@{
                Action = "None"
                Continue = $false
            }
        }
    }
}

function Search-MenuItems {
    <#
    .SYNOPSIS
        Searches menu items by text.
    .PARAMETER MenuItems
        Hashtable of menu items.
    .PARAMETER SearchTerm
        The search term.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$MenuItems,
        
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm
    )
    
    $results = @{}
    
    foreach ($key in $MenuItems.Keys) {
        $item = $MenuItems[$key]
        $text = if ($item -is [hashtable]) { $item.Text } else { $item }
        
        if ($text -like "*$SearchTerm*") {
            $results[$key] = $item
        }
    }
    
    return $results
}

function Get-StandardBackOption {
    <#
    .SYNOPSIS
        Returns a standard "Back" menu option.
    .PARAMETER KeyValue
        The key value for the back option (default is "0").
    .PARAMETER Text
        Custom text for the back option.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$KeyValue = "0",
        
        [Parameter(Mandatory = $false)]
        [string]$Text = "← Back to Previous Menu"
    )
    
    return @{
        $KeyValue = @{
            Text = $Text
            Color = "Yellow"
        }
    }
}

function Format-ErrorMessage {
    <#
    .SYNOPSIS
        Formats error messages with actionable guidance.
    .PARAMETER ErrorMessage
        The error message.
    .PARAMETER PossibleCauses
        Array of possible causes.
    .PARAMETER SuggestedActions
        Array of suggested actions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [string[]]$PossibleCauses,
        
        [Parameter(Mandatory = $false)]
        [string[]]$SuggestedActions
    )
    
    Write-Host ""
    Write-Host "═══ ERROR ═══" -ForegroundColor Red
    Write-Host $ErrorMessage -ForegroundColor Red
    
    if ($PossibleCauses -and $PossibleCauses.Count -gt 0) {
        Write-Host ""
        Write-Host "Possible causes:" -ForegroundColor Yellow
        $PossibleCauses | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor White
        }
    }
    
    if ($SuggestedActions -and $SuggestedActions.Count -gt 0) {
        Write-Host ""
        Write-Host "Suggested actions:" -ForegroundColor Cyan
        $SuggestedActions | ForEach-Object {
            Write-Host "  → $_" -ForegroundColor White
        }
    }
    
    Write-Host ""
}
