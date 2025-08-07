function Update-ProgressBar {
    <#
    .SYNOPSIS
        Updates an existing progress bar.
    .DESCRIPTION
        Updates the display of a progress bar with new percentage and status information.
    .PARAMETER PercentComplete
        The percentage of completion (0-100).
    .PARAMETER Status
        Additional status text displayed after the progress bar.
    .PARAMETER Width
        The width of the progress bar in characters. Default is 50.
    .PARAMETER Activity
        The activity description displayed before the progress bar. Default is "Progress".
    .PARAMETER NoPercentage
        If specified, hides the percentage display.
    .EXAMPLE
        Update-ProgressBar -PercentComplete 50 -Status "Processing..."
    .EXAMPLE
        Update-ProgressBar -PercentComplete 75 -Status "Uploading files..." -Activity "File Transfer"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$PercentComplete,
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$Activity = "Progress",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPercentage
    )
    
    # Clear the current line and show the updated progress bar
    Clear-CurrentLine
    Show-ProgressBar -PercentComplete $PercentComplete -Width $Width -Activity $Activity -Status $Status -NoPercentage:$NoPercentage -NoNewLine
}
