<#
.SYNOPSIS
    Displays the status of background monitoring jobs in the console.
.DESCRIPTION
    Shows a formatted list of all background monitoring jobs with their current status.
.EXAMPLE
    Show-BackgroundMonitoringDetails
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-BackgroundMonitoringDetails {
    [CmdletBinding()]
    param()
    
    $jobs = Get-BackgroundMonitoringJobs
    
    if ($jobs.Count -eq 0) {
        Write-ColorOutput "No background monitoring jobs found." -ForegroundColor Yellow
        return
    }
    
    Write-ColorOutput "`nBackground Monitoring Jobs:" -ForegroundColor Cyan
    Write-ColorOutput "=========================" -ForegroundColor Cyan
    
    foreach ($job in $jobs) {
        $elapsedTime = if ($job.EndTime) {
            $timeSpan = $job.EndTime - $job.StartTime
            "{0:hh\:mm\:ss}" -f $timeSpan
        } else {
            $timeSpan = (Get-Date) - $job.StartTime
            "{0:hh\:mm\:ss}" -f $timeSpan
        }
        
        $statusColor = switch ($job.Status) {
            "Running" { "Yellow" }
            "Completed" { 
                if ($job.Result.Status -eq "Succeeded") { "Green" } 
                elseif ($job.Result.Status -eq "Failed") { "Red" }
                else { "Yellow" }
            }
            "Failed" { "Red" }
            default { "White" }
        }
        
        # Display job information
        Write-ColorOutput "  Job ID: $($job.JobId)" -ForegroundColor White
        Write-ColorOutput "  Resource: $($job.ResourceType) '$($job.ResourceName)'" -ForegroundColor Cyan
        Write-ColorOutput "  Status: " -ForegroundColor White -NoNewline
        
        if ($job.Status -eq "Completed" -and $job.Result) {
            Write-ColorOutput "$($job.Result.Status)" -ForegroundColor $statusColor
        } else {
            Write-ColorOutput "$($job.Status)" -ForegroundColor $statusColor
        }
        
        Write-ColorOutput "  Elapsed Time: $elapsedTime" -ForegroundColor White
        
        # For completed jobs with results, show additional information
        if ($job.Status -eq "Completed" -and $job.Result) {
            if ($job.Result.LogFile -and (Test-Path $job.Result.LogFile)) {
                Write-ColorOutput "  Log File: $($job.Result.LogFile)" -ForegroundColor White
            }
        }
        
        Write-ColorOutput "" # Empty line between jobs
    }
}
