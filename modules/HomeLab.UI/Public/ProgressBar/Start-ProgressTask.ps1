<#
.SYNOPSIS
    Executes a task with progress reporting.
.DESCRIPTION
    Executes a script block with progress reporting using a synchronized hash table.
.PARAMETER Activity
    The name of the activity being performed.
.PARAMETER TotalSteps
    The total number of steps in the activity.
.PARAMETER ScriptBlock
    The script block to execute.
.PARAMETER ArgumentList
    Optional arguments to pass to the script block.
.EXAMPLE
    Start-ProgressTask -Activity "Deploying Resources" -TotalSteps 4 -ScriptBlock { ... }
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Start-ProgressTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalSteps,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList
    )
    
    # Initialize synchronization hash table if not already done
    if (-not $Global:syncHash) {
        $Global:syncHash = [hashtable]::Synchronized(@{})
    }
    
    $Global:syncHash.Activity = $Activity
    $Global:syncHash.Status = "Initializing..."
    $Global:syncHash.CurrentStep = 0
    $Global:syncHash.TotalSteps = $TotalSteps
    
    # Execute the script block with arguments if provided
    if ($ArgumentList) {
        & $ScriptBlock @ArgumentList
    }
    else {
        & $ScriptBlock
    }
}
