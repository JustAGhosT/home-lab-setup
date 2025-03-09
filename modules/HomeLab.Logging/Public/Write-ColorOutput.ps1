function Write-ColorOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine
    )
    
    $params = @{
        Object = $Text
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline = $NoNewLine
    }
    
    Write-Host @params
}
