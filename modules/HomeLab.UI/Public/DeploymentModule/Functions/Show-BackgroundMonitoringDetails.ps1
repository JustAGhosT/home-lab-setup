<#
.SYNOPSIS
    Shows background monitoring job details
.DESCRIPTION
    Displays information about background monitoring jobs and provides options to clean up completed jobs
.PARAMETER Config
    The configuration object containing deployment settings
.PARAMETER TargetInfo
    A formatted string describing the deployment target
.EXAMPLE
    Show-BackgroundMonitoringDetails -Config $config -TargetInfo "[Target: dev-saf-homelab]"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-BackgroundMonitoringDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetInfo
    )
    
    Write-ColorOutput "Background Monitoring Status... $TargetInfo" -ForegroundColor Cyan
    
    # Display all background monitoring jobs
    Show-BackgroundMonitoringStatus
    
    # Option to clean up completed jobs
    $cleanupConfirmation = Read-Host "`nWould you like to clean up completed monitoring jobs? (Y/N)"
    if ($cleanupConfirmation -eq "Y" -or $cleanupConfirmation -eq "y") {
        $completedJobs = Get-Job | Where-Object { $_.Name -like "Monitor_*" -and $_.State -eq "Completed" }
        if ($completedJobs) {
            $completedJobs | Remove-Job
            Write-ColorOutput "Completed monitoring jobs have been removed." -ForegroundColor Green
        } else {
            Write-ColorOutput "No completed monitoring jobs to clean up." -ForegroundColor Yellow
        }
    }
    
    Pause
}
