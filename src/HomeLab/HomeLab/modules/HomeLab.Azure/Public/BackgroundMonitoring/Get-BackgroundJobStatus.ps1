function Get-BackgroundJobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$JobName,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeOutput
    )
    
    Write-Log -Message "Checking background job status..." -Level Info
    
    # Get all jobs or filter by name
    $jobs = if ($JobName) { Get-Job -Name $JobName* } else { Get-Job }
    
    if (-not $jobs) {
        Write-Log -Message "No background jobs found." -Level Info
        return
    }
    
    $jobInfo = @()
    
    foreach ($job in $jobs) {
        $status = @{
            Id = $job.Id
            Name = $job.Name
            State = $job.State
            StartTime = $job.PSBeginTime
            Duration = if ($job.PSBeginTime) { 
                (New-TimeSpan -Start $job.PSBeginTime -End (Get-Date)).ToString("hh\:mm\:ss") 
            } else { "Unknown" }
        }
        
        if ($IncludeOutput -and $job.State -eq "Completed") {
            try {
                $output = Receive-Job -Job $job -Keep
                $status.Output = $output
            }
            catch {
                $status.Output = "Error retrieving output: $_"
            }
        }
        
        $jobInfo += New-Object PSObject -Property $status
    }
    
    # Display job info
    $jobInfo | Format-Table -AutoSize -Property Id, Name, State, StartTime, Duration
    
    if ($IncludeOutput) {
        foreach ($info in $jobInfo) {
            if ($info.Output) {
                Write-Host "`nOutput for job $($info.Name) (ID: $($info.Id)):" -ForegroundColor Cyan
                $info.Output
            }
        }
    }
    
    return $jobInfo
}
