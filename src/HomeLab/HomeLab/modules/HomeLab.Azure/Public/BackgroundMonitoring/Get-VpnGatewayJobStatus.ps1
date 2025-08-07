function Get-VpnGatewayJobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$JobResult
    )
    
    $deploymentJob = Get-Job -Id $JobResult.DeploymentJob.JobId -ErrorAction SilentlyContinue
    $monitoringJobId = $JobResult.MonitoringJob.JobId
    
    $status = @{
        Deployment = if ($deploymentJob) {
            @{
                State = $deploymentJob.State
                HasMoreData = $deploymentJob.HasMoreData
                Output = if ($deploymentJob.State -eq 'Completed') { Receive-Job -Id $deploymentJob.Id -Keep } else { "Job still running" }
            }
        } else {
            "Job not found"
        }
        
        Monitoring = @{
            JobId = $monitoringJobId
            LogFile = $JobResult.MonitoringJob.LogFile
        }
    }
    
    return $status
}
