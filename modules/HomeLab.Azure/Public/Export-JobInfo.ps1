<#
.SYNOPSIS
    Exports background job information to a file.
.DESCRIPTION
    Writes key details of a background job (name, job ID, state, command, timestamps)
    to a text file in the TEMP folder.
.PARAMETER Job
    The background job object to export.
.PARAMETER OutputPath
    Optional. The file path for the output. Defaults to "$env:TEMP\JobInfo_<JobName>.txt".
.EXAMPLE
    Export-JobInfo -Job $job
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Export-JobInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Job,
        
        [Parameter(Mandatory=$false)]
        [string]$Name = "Job"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportPath = Join-Path -Path $env:TEMP -ChildPath "JobInfo_${Name}${timestamp}.txt"
        
        # Create a string representation of the job info
        $jobDetails = ""
        
        # Handle different types of job objects
        if ($Job -is [System.Management.Automation.Job]) {
            $jobDetails = @"
Job ID: $($Job.Id)
Job Name: $($Job.Name)
State: $($Job.State)
Start Time: $($Job.PSBeginTime)
Command: $($Job.Command)
"@
        }
        elseif ($Job -is [hashtable]) {
            # Convert hashtable to formatted string
            $jobDetails = $Job.GetEnumerator() | ForEach-Object {
                if ($_.Value -is [hashtable]) {
                    "$($_.Key):`n" + ($_.Value.GetEnumerator() | ForEach-Object { "  $($_.Key): $($_.Value)" } | Out-String)
                } else {
                    "$($_.Key): $($_.Value)"
                }
            } | Out-String
        }
        else {
            # For any other object type, convert to string safely
            $jobDetails = $Job | Out-String
        }
        
        # Write to file
        $jobDetails | Out-File -FilePath $exportPath
        
        Write-Log -Message "Job info exported to $exportPath" -Level Info
        return $exportPath
    }
    catch {
        Write-Log -Message "Failed to export job info: $_" -Level Error
        return $null
    }
}
