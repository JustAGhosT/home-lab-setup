function Show-BackgroundJobInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Job]$Job,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-ColorOutput "=== JOB INFORMATION ===" -ForegroundColor Cyan
    Write-ColorOutput "Job ID: $($Job.Id)" -ForegroundColor Cyan
    Write-ColorOutput "Name: $($Job.Name)" -ForegroundColor Cyan
    Write-ColorOutput "State: $($Job.State)" -ForegroundColor $(
        switch ($Job.State) {
            'Running' { 'Yellow' }
            'Completed' { 'Green' }
            'Failed' { 'Red' }
            default { 'White' }
        }
    )
    Write-ColorOutput "Command: $($Job.Command)" -ForegroundColor Cyan
    
    if ($Detailed) {
        Write-ColorOutput "=== DETAILED INFORMATION ===" -ForegroundColor Cyan
        
        # Format job properties as a list and display
        $jobDetails = $Job | Format-List * | Out-String
        Write-ColorOutput $jobDetails -ForegroundColor White
        
        # Show job output if available
        if ($Job.State -eq 'Completed') {
            Write-ColorOutput "=== JOB OUTPUT ===" -ForegroundColor Green
            $output = Receive-Job -Job $Job -Keep | Out-String
            if ([string]::IsNullOrWhiteSpace($output)) {
                Write-ColorOutput "(No output)" -ForegroundColor DarkGray
            }
            else {
                Write-ColorOutput $output -ForegroundColor White
            }
        }
    }
    
    Write-ColorOutput "======================" -ForegroundColor Cyan
}
