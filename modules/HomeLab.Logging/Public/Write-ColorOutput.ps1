<#
.SYNOPSIS
    Writes colored text to the console.
.DESCRIPTION
    Outputs text to the console with specified foreground and background colors.
.PARAMETER Text
    The text to display.
.PARAMETER ForegroundColor
    The text color to use.
.PARAMETER BackgroundColor
    The background color to use.
.PARAMETER NoNewLine
    If specified, doesn't add a newline after the output.
.EXAMPLE
    Write-ColorOutput "Success!" -ForegroundColor Green
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
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
        [switch]$NoNewLine
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
    
    $params = @{
        Object = $textString
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline = $NoNewLine
    }
    
    Write-Host @params
}
