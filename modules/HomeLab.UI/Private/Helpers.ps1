<#
.SYNOPSIS
    Internal helper functions for HomeLab.UI module.
.DESCRIPTION
    Contains internal helper functions used by the HomeLab.UI module.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

function Write-ColorOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    Write-Host $Text -ForegroundColor $Color
}

function Clear-CurrentLine {
    [CmdletBinding()]
    param()
    
    $cursorTop = [Console]::CursorTop
    [Console]::SetCursorPosition(0, $cursorTop)
    [Console]::Write(new-object string(' ', [Console]::WindowWidth))
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
