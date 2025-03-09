<#
.SYNOPSIS
    Exports the background job information to a file.
.DESCRIPTION
    This function takes a background job and writes key details (job name, ID, state, command, and timestamps)
    to a text file in the TEMP folder. A default output path is provided unless overridden.
.PARAMETER Job
    The background job object to export information from.
.PARAMETER OutputPath
    Optional. The path to the output file. Defaults to "$env:TEMP\JobInfo_<JobName>.txt".
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
        [System.Management.Automation.Job]$Job,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$env:TEMP\JobInfo_$($Job.Name).txt"
    )
    
    # Create a PSCustomObject with selected job properties.
    $jobInfo = [PSCustomObject]@{
        Name        = $Job.Name
        JobId       = $Job.Id
        State       = $Job.State
        HasMoreData = $Job.HasMoreData
        Command     = $Job.Command
        PSBeginTime = $Job.PSBeginTime
        PSEndTime   = $Job.PSEndTime
    }
    
    # Format and output to file.
    $jobInfo | Format-List | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Job info exported to $OutputPath" -ForegroundColor Green
}
