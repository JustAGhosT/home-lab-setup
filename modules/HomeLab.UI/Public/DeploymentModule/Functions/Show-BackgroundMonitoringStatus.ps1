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
    Show-BackgroundMonitoringStatus -Config $config -TargetInfo "[Target: dev-saf-homelab]"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-BackgroundMonitoringStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetInfo
    )
    
    Write-ColorOutput "Background Monitoring Status... $TargetInfo" -ForegroundColor Cyan
    
    # Make sure the function exists before calling it
    if (Get-Command -Name Show-BackgroundMonitoringDetails -ErrorAction SilentlyContinue) {
        # Display all background monitoring jobs
        Show-BackgroundMonitoringDetails
    }
    else {
        Write-ColorOutput "Error: The Show-BackgroundMonitoringDetails function is not available." -ForegroundColor Red
        Write-ColorOutput "This may indicate an issue with module loading or function exports." -ForegroundColor Red
        
        # Fallback implementation - directly get and display jobs
        $jobs = Get-Job | Where-Object { $_.Name -like "Monitor_*" }
        if ($jobs.Count -gt 0) {
            Write-ColorOutput "`nFound $($jobs.Count) monitoring jobs:" -ForegroundColor Yellow
            foreach ($job in $jobs) {
                Write-ColorOutput "  Job ID: $($job.Id), Name: $($job.Name), Status: $($job.State)" -ForegroundColor White
            }
        }
        else {
            Write-ColorOutput "No background monitoring jobs found." -ForegroundColor Yellow
        }
    }
    
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
 