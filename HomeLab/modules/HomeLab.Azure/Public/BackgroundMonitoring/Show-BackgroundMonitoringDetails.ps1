<#
.SYNOPSIS
    Shows details of background monitoring jobs.
.DESCRIPTION
    Displays information about currently running background monitoring jobs
    including resource type, name, status, and elapsed time.
.PARAMETER CleanupCompleted
    If specified, automatically removes completed jobs without prompting.
.EXAMPLE
    Show-BackgroundMonitoringDetails
    
    Shows all background monitoring jobs and prompts to clean up completed jobs.
.EXAMPLE
    Show-BackgroundMonitoringDetails -CleanupCompleted
    
    Shows all background monitoring jobs and automatically cleans up completed ones.
#>
function Show-BackgroundMonitoringDetails {
    [CmdletBinding()]
    param(
        [switch]$CleanupCompleted
    )
    
    # Get job directory path
    $jobDir = Join-Path -Path $env:TEMP -ChildPath "HomeLab\Jobs"
    if (-not (Test-Path -Path $jobDir)) {
        Write-Host "`nNo background monitoring jobs found.`n" -ForegroundColor Yellow
        return
    }
    
    # Get all job files
    $jobFiles = Get-ChildItem -Path $jobDir -Filter "job_*.xml" -ErrorAction SilentlyContinue
    if (-not $jobFiles -or $jobFiles.Count -eq 0) {
        Write-Host "`nNo background monitoring jobs found.`n" -ForegroundColor Yellow
        return
    }
    
    # Process job files
    $jobs = @()
    foreach ($file in $jobFiles) {
        try {
            $jobInfo = Import-Clixml -Path $file.FullName
            $jobs += [PSCustomObject]@{
                JobId = $jobInfo.JobId
                Path = $file.FullName
                Info = $jobInfo
            }
        }
        catch {
            Write-Warning "Failed to read job file: $($file.FullName)"
        }
    }
    
    if ($jobs.Count -eq 0) {
        Write-Host "`nNo valid background monitoring jobs found.`n" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nBackground Monitoring Jobs:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    foreach ($job in $jobs) {
        $jobInfo = $job.Info
        $elapsedTime = [DateTime]::Now - $jobInfo.StartTime
        $formattedTime = "{0:hh\:mm\:ss}" -f $elapsedTime
        
        # Extract resource information
        $resourceType = $jobInfo.ResourceType ?? "Unknown Resource"
        $resourceName = $jobInfo.ResourceName ?? "Unknown Name"
        $resourceGroup = $jobInfo.ResourceGroupName ?? "Unknown Group"
        
        # Get job status
        $status = "Unknown"
        if ($jobInfo.Job -and (Get-Job -Id $jobInfo.Job.Id -ErrorAction SilentlyContinue)) {
            $jobStatus = Get-Job -Id $jobInfo.Job.Id
            $status = $jobStatus.State
            
            # Check for completed job with results
            if ($status -eq "Completed") {
                try {
                    $result = Receive-Job -Id $jobInfo.Job.Id -Keep -ErrorAction SilentlyContinue
                    if ($result -and $result.Status) {
                        $status = $result.Status
                    }
                }
                catch {
                    # Ignore errors in receiving job results
                }
            }
        }
        else {
            $status = "Not Found"
        }
        
        # Display job info with better formatting
        Write-Host "  Job ID: $($job.JobId)" -ForegroundColor Yellow
        Write-Host "  Resource: $resourceType '$resourceName'" -ForegroundColor Cyan
        Write-Host "  Resource Group: $resourceGroup" -ForegroundColor Cyan
        if ($jobInfo.DeploymentName) {
            Write-Host "  Deployment: $($jobInfo.DeploymentName)" -ForegroundColor Cyan
        }
        
        # Color-code status
        $statusColor = switch ($status) {
            "Running" { "Green" }
            "Completed" { "Green" }
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "Stopped" { "Yellow" }
            "Timeout" { "Yellow" }
            "Not Found" { "Red" }
            default { "White" }
        }
        
        Write-Host "  Status: $status" -ForegroundColor $statusColor
        Write-Host "  Elapsed Time: $formattedTime" -ForegroundColor White
        
        # Show log file if available
        if ($jobInfo.LogFile -or ($result -and $result.LogFile)) {
            $logFile = $jobInfo.LogFile ?? $result.LogFile
            if (Test-Path $logFile) {
                Write-Host "  Log File: $logFile" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
    }
    
    # Handle cleanup of completed jobs
    $completedJobs = $jobs | Where-Object { 
        $jobInfo = $_.Info
        if (-not $jobInfo.Job) { return $false }
        
        $jobId = $jobInfo.Job.Id
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
        return ($job -and $job.State -ne "Running") -or (-not $job)
    }
    
    if ($completedJobs.Count -gt 0) {
        $cleanupJobs = $false
        
        if ($CleanupCompleted) {
            $cleanupJobs = $true
        } else {
            $response = Read-Host "Would you like to clean up completed monitoring jobs? (Y/N)"
            $cleanupJobs = $response -like "Y*"
        }
        
        if ($cleanupJobs) {
            foreach ($job in $completedJobs) {
                $jobInfo = $job.Info
                
                # Remove the job if it exists
                if ($jobInfo.Job) {
                    $jobId = $jobInfo.Job.Id
                    Get-Job -Id $jobId -ErrorAction SilentlyContinue | Remove-Job -Force
                }
                
                # Remove the job file
                Remove-Item -Path $job.Path -Force
                
                Write-Host "Cleaned up job $($job.JobId)" -ForegroundColor Green
            }
            
            Write-Host "Completed jobs have been cleaned up." -ForegroundColor Green
        }
    }
}
