<#
.SYNOPSIS
    Internal helper functions for HomeLab.UI module.
.DESCRIPTION
    Contains internal helper functions used by the HomeLab.UI module.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>



function Clear-CurrentLine {
    [CmdletBinding()]
    param()
    
    $cursorTop = [Console]::CursorTop
    [Console]::SetCursorPosition(0, $cursorTop)
    # Fixed line - using .NET syntax for string creation
    [Console]::Write(([string]::new(' ', [Console]::WindowWidth)))
    [Console]::SetCursorPosition(0, $cursorTop)
}

function Get-WindowSize {
    [CmdletBinding()]
    param()
    
    return @{
        Width = [Console]::WindowWidth
        Height = [Console]::WindowHeight
    }
}

<#
.SYNOPSIS
    Helper functions for HomeLab UI
.DESCRIPTION
    Contains utility functions used by the HomeLab UI components
.NOTES
    Part of HomeLab.UI module
#>

function Format-MenuHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 60
    )
    
    $padding = [Math]::Max(0, ($Width - $Title.Length - 4) / 2)
    $leftPad = [Math]::Floor($padding)
    $rightPad = [Math]::Ceiling($padding)
    
    Write-Host ("═" * $Width) -ForegroundColor Cyan
    Write-Host ("═" * $leftPad) -ForegroundColor Cyan -NoNewline
    Write-Host " $Title " -ForegroundColor White -NoNewline
    Write-Host ("═" * $rightPad) -ForegroundColor Cyan
    Write-Host ("═" * $Width) -ForegroundColor Cyan
}

function Format-MenuFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Width = 60
    )
    
    Write-Host ("═" * $Width) -ForegroundColor Cyan
}

function Get-UserChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Prompt = "Enter your choice",
        
        [Parameter(Mandatory = $false)]
        [string[]]$ValidOptions,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultOption
    )
    
    $choice = ""
    do {
        Write-Host "$Prompt" -ForegroundColor Yellow -NoNewline
        if ($DefaultOption) {
            Write-Host " [$DefaultOption]" -ForegroundColor Cyan -NoNewline
        }
        Write-Host ": " -NoNewline
        $choice = Read-Host
        
        # Use default if empty
        if ([string]::IsNullOrWhiteSpace($choice) -and $DefaultOption) {
            $choice = $DefaultOption
        }
        
        # Validate if options are specified
        if ($ValidOptions -and $ValidOptions.Count -gt 0) {
            if ($choice -notin $ValidOptions) {
                Write-Host "Invalid option. Please choose from: $($ValidOptions -join ', ')" -ForegroundColor Red
                $choice = ""
            }
        }
    } while ([string]::IsNullOrWhiteSpace($choice))
    
    return $choice
}

function Clear-HostSafe {
    [CmdletBinding()]
    param()
    
    # Check if we're in a console or ISE
    if ($host.Name -eq 'ConsoleHost') {
        Clear-Host
    }
    else {
        # For ISE or other hosts, print blank lines
        1..50 | ForEach-Object { Write-Host "" }
    }
}

function Show-Notification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Type = 'Info',
        
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 2
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Warning' = 'Yellow'
        'Error' = 'Red'
        'Success' = 'Green'
    }
    
    $color = $colors[$Type]
    $icon = switch ($Type) {
        'Info' { 'ℹ️' }
        'Warning' { '⚠️' }
        'Error' { '❌' }
        'Success' { '✓' }
    }
    
    Write-Host ""
    Write-Host " $icon $Message" -ForegroundColor $color
    Write-Host ""
    
    if ($DurationSeconds -gt 0) {
        Start-Sleep -Seconds $DurationSeconds
    }
}
