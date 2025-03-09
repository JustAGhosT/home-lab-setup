function Start-ProgressTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$TotalSteps = 100
    )
    
    # Execute the script block directly without background runspaces
    try {
        # Create a simple status object to track progress
        $status = [PSCustomObject]@{
            Activity = $Activity
            CurrentStep = 0
            TotalSteps = $TotalSteps
            Status = ""
        }
        
        # Make it available to the script block
        $Global:syncHash = $status
        
        # Show initial progress
        Write-Progress -Activity $Activity -Status "Starting..." -PercentComplete 0
        
        # Execute the script block
        $result = & $ScriptBlock
        
        # Show completion
        Write-Progress -Activity $Activity -Status "Complete" -PercentComplete 100 -Completed
        
        # Return the result
        return $result
    }
    catch {
        Write-Progress -Activity $Activity -Status "Error" -PercentComplete 100 -Completed
        Write-Error "Error in task: $_"
        return "Error during task: $_"
    }
    finally {
        # Clean up the global variable
        Remove-Variable -Name syncHash -Scope Global -ErrorAction SilentlyContinue
    }
}
