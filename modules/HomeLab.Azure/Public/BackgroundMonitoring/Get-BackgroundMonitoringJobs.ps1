<#
.SYNOPSIS
    Gets the status of all background monitoring jobs.
.DESCRIPTION
    Retrieves information about all running and completed background monitoring jobs.
.EXAMPLE
    Get-BackgroundMonitoringJobs
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Get-BackgroundMonitoringJobs {
    [CmdletBinding()]
    param()
    
    # Get all jobs with names starting with "Monitor_"
    $jobs = Get-Job | Where-Object { $_.Name -like "Monitor_*" }
    
    $results = @()
    
    foreach ($job in $jobs) {
        $status = $job.State
        $result = $null
        
        # For completed jobs, get the result
        if ($status -eq "Completed") {
            $result = Receive-Job -Job $job -Keep
        }
        
        # Extract resource info from job name
        $resourceInfo = $job.Name -replace "Monitor_", ""
        $resourceParts = $resourceInfo -split "_"
        $resourceType = $resourceParts[0]
        $resourceName = $resourceParts[1]
        
        # Create result object
        $jobInfo = [PSCustomObject]@{
            JobId = $job.Id
            JobName = $job.Name
            ResourceType = $resourceType
            ResourceName = $resourceName
            Status = $status
            StartTime = $job.PSBeginTime
            EndTime = $job.PSEndTime
            Result = $result
        }
        
        $results += $jobInfo
    }
    
    return $results
}