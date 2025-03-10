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
    
    # If NoNewLine is specified, we need special handling
    if ($NoNewLine) {
        # For NoNewLine, we need to use Write-Host directly
        $params = @{
            Object = $textString
            ForegroundColor = $ForegroundColor
            BackgroundColor = $BackgroundColor
            NoNewline = $true
        }
        
        Write-Host @params
        
        # Also log to file if not suppressed
        if (-not $NoLog) {
            # Convert the color to a string name
            $colorName = $colorMap[$ForegroundColor.ToString()]
            
            # Write to log file only (NoConsole)
            Write-Log -Message $textString -Level $Level -Color $colorName -NoConsole
        }
    }
    else {
        # Normal case - use Write-Log
        $colorName = $colorMap[$ForegroundColor.ToString()]
        $writeLogParams = @{
            Message = $textString
            Level = $Level
            Color = $colorName
        }
        
        if ($NoLog) {
            $writeLogParams.NoLog = $true
        }
        
        Write-Log @writeLogParams
    }
}
