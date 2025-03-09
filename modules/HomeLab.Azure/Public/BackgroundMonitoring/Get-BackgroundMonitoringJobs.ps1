<#
.SYNOPSIS
    Retrieves all background monitoring jobs.
.DESCRIPTION
    Gets information about all background monitoring jobs, including their status and results.
.EXAMPLE
    $jobs = Get-BackgroundMonitoringJobs
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Get-BackgroundMonitoringJobs {
    [CmdletBinding()]
    param()
    
    # Get all jobs with the Monitor_ prefix
    $monitorJobs = Get-Job | Where-Object { $_.Name -like "Monitor_*" }
    $jobDetails = @()
    
    foreach ($job in $monitorJobs) {
        $jobInfo = [PSCustomObject]@{
            JobId = $job.Id
            JobName = $job.Name
            Status = $job.State
            ResourceType = "Unknown"
            ResourceName = "Unknown"
            StartTime = $job.PSBeginTime
            EndTime = $job.PSEndTime
            Result = $null
        }
        
        # Try to extract resource information from job name
        if ($job.Name -match "Monitor_(.+?)_(.+?)_\d+") {
            $jobInfo.ResourceType = $matches[1]
            $jobInfo.ResourceName = $matches[2]
        }
        
        # For completed jobs, try to get the result
        if ($job.State -eq "Completed") {
            try {
                $jobResult = Receive-Job -Id $job.Id -Keep
                if ($jobResult) {
                    $jobInfo.Result = $jobResult
                }
            }
            catch {
                # Just continue if we can't get the result
            }
        }
        
        $jobDetails += $jobInfo
    }
    
    return $jobDetails
}
