<#
.SYNOPSIS
    Writes colored text to the console.
.DESCRIPTION
    Outputs text to the console with specified foreground and background colors.
    Uses Write-Log internally for consistent logging behavior.
.PARAMETER Text
    The text to display.
.PARAMETER ForegroundColor
    The text color to use.
.PARAMETER BackgroundColor
    The background color to use.
.PARAMETER NoNewLine
    If specified, doesn't add a newline after the output.
.PARAMETER Level
    The log level to use (defaults to Info).
.PARAMETER NoLog
    If specified, doesn't write to the log file.
.EXAMPLE
    Write-ColorOutput "Success!" -ForegroundColor Green
.NOTES
    Author: Jurie Smit
    Date: March 10, 2025
#>
function Write-ColorOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [AllowNull()]
        $Text,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info','Warning','Error','Success', 'Debug', 'Verbose', IgnoreCase = $true)]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [switch]$NoLog
    )
    
    # Convert input to string safely
    if ($null -eq $Text) {
        $textString = "[null]"
    }
    else {
        try {
            $textString = $Text.ToString()
        }
        catch {
            $textString = "[Object cannot be converted to string]"
        }
    }
    
    # Skip logging empty lines
    $skipLogging = [string]::IsNullOrWhiteSpace($textString)
    
    # Map ConsoleColor to string color name for Write-Log
    $colorMap = @{
        'Black' = 'Black'
        'DarkBlue' = 'DarkBlue'
        'DarkGreen' = 'DarkGreen'
        'DarkCyan' = 'DarkCyan'
        'DarkRed' = 'DarkRed'
        'DarkMagenta' = 'DarkMagenta'
        'DarkYellow' = 'DarkYellow'
        'Gray' = 'Gray'
        'DarkGray' = 'DarkGray'
        'Blue' = 'Blue'
        'Green' = 'Green'
        'Cyan' = 'Cyan'
        'Red' = 'Red'
        'Magenta' = 'Magenta'
        'Yellow' = 'Yellow'
        'White' = 'White'
    }
    
    $colorName = $colorMap[$ForegroundColor.ToString()]
    
    # For UI elements (menus, prompts, etc.), we want to:
    # 1. Write directly to console with colors but no timestamp/level prefix
    # 2. Log to file with timestamp/level prefix
    
    # Direct console output with colors
    if ($NoNewLine) {
        Write-Host $textString -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline
    } else {
        Write-Host $textString -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
    
    # Log to file if not empty and not suppressed
    if (-not $skipLogging -and -not $NoLog) {
        Write-Log -Message $textString -Level $Level -Color $colorName -NoConsole
    }
}