function Show-ProgressBar {
    <#
    .SYNOPSIS
        Displays a text-based progress bar in the console.
    .DESCRIPTION
        Creates and displays a customizable text-based progress bar in the console with optional status text.
    .PARAMETER PercentComplete
        The percentage of completion (0-100).
    .PARAMETER Width
        The width of the progress bar in characters. Default is 50.
    .PARAMETER Activity
        The activity description displayed before the progress bar. Default is "Progress".
    .PARAMETER Status
        Additional status text displayed after the progress bar.
    .PARAMETER ForegroundColor
        The color of the progress bar. Default is Green.
    .PARAMETER BackgroundColor
        The color of the empty part of the progress bar. Default is DarkGray.
    .PARAMETER NoPercentage
        If specified, hides the percentage display.
    .PARAMETER NoNewLine
        If specified, doesn't add a new line after the progress bar.
    .PARAMETER ReturnString
        If specified, returns the progress bar as a string instead of displaying it.
    .EXAMPLE
        Show-ProgressBar -PercentComplete 50 -Activity "Deploying" -Status "Creating resources..."
    .EXAMPLE
        Show-ProgressBar -PercentComplete 75 -Width 30 -ForegroundColor Cyan -NoPercentage
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$PercentComplete,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$Activity = "Progress",
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Green,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::DarkGray,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPercentage,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnString
    )
    
    # Ensure percent complete is within valid range
    $PercentComplete = [Math]::Max(0, [Math]::Min(100, $PercentComplete))
    
    # Calculate the number of blocks to display
    $numBlocks = [Math]::Round($Width * ($PercentComplete / 100))
    
    # Create the progress bar
    $progressBar = "["
    $progressBar += "█" * $numBlocks
    $progressBar += " " * ($Width - $numBlocks)
    $progressBar += "]"
    
    # Add percentage if requested
    if (-not $NoPercentage) {
        $progressBar += " {0,3:N0}%" -f $PercentComplete
    }
    
    # Add status if provided
    if ($Status) {
        $progressBar += " - $Status"
    }
    
    if ($ReturnString) {
        return $progressBar
    }
    else {
        # Clear the current line before writing the progress bar
        Clear-CurrentLine
        
        # Display the activity if provided
        if ($Activity -ne "Progress") {
            Write-Host "$Activity " -NoNewline
        }
        
        # Display the progress bar with colors
        $originalFg = [Console]::ForegroundColor
        $originalBg = [Console]::BackgroundColor
        
        try {
            [Console]::ForegroundColor = $ForegroundColor
            [Console]::BackgroundColor = $BackgroundColor
            Write-Host $progressBar -NoNewline:$NoNewLine
        }
        finally {
            [Console]::ForegroundColor = $originalFg
            [Console]::BackgroundColor = $originalBg
            
            if (-not $NoNewLine) {
                Write-Host ""
            }
        }
    }
}