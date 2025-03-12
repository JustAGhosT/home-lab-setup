function Export-JobInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Job,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$DeploymentInfo,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$MonitoringInfo,
        
        [Parameter(Mandatory=$false)]
        [string]$Name = "Job"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportPath = Join-Path -Path $env:TEMP -ChildPath "JobInfo_${Name}_${timestamp}.txt"
        
        # Create a StringBuilder for better performance with large strings
        $output = New-Object System.Text.StringBuilder
        
        # Add deployment information if provided
        if ($DeploymentInfo) {
            [void]$output.AppendLine("Deployment Job:")
            foreach ($key in $DeploymentInfo.Keys | Sort-Object) {
                # Fixed string interpolation by using proper string concatenation
                [void]$output.AppendLine("- " + $key + ": " + $DeploymentInfo[$key])
            }
            [void]$output.AppendLine("")
        }
        
        # Add monitoring information if provided
        if ($MonitoringInfo) {
            [void]$output.AppendLine("Monitoring Details:")
            [void]$output.AppendLine("")
            
            # Format as a table header
            [void]$output.AppendLine("Name                           Value")
            [void]$output.AppendLine("----                           -----")
            
            # Add each key-value pair
            if ($MonitoringInfo -is [hashtable]) {
                foreach ($key in $MonitoringInfo.Keys | Sort-Object) {
                    # Fixed string interpolation using proper string concatenation
                    [void]$output.AppendLine(($key.ToString().PadRight(30)) + " " + $MonitoringInfo[$key])
                }
            }
            else {
                # If MonitoringInfo is not a hashtable, try to format it differently
                [void]$output.AppendLine("Monitoring object type: " + $MonitoringInfo.GetType().FullName)
                [void]$output.AppendLine("Monitoring object value: " + $MonitoringInfo)
            }
        }
        
        # Add standard job information if provided
        if ($Job -and -not $DeploymentInfo -and -not $MonitoringInfo) {
            if ($Job -is [System.Management.Automation.Job]) {
                [void]$output.AppendLine("Job ID: " + $Job.Id)
                [void]$output.AppendLine("Job Name: " + $Job.Name)
                [void]$output.AppendLine("State: " + $Job.State)
                [void]$output.AppendLine("Start Time: " + $Job.PSBeginTime)
                [void]$output.AppendLine("Command: " + $Job.Command)
            }
            elseif ($Job -is [hashtable]) {
                foreach ($key in $Job.Keys | Sort-Object) {
                    # Fixed string interpolation
                    [void]$output.AppendLine($key + ": " + $Job[$key])
                }
            }
            else {
                # For any other object type, convert properties to string
                $properties = $Job | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
                foreach ($prop in $properties | Sort-Object) {
                    # Fixed string interpolation
                    $propValue = $Job | Select-Object -ExpandProperty $prop
                    [void]$output.AppendLine($prop + ": " + $propValue)
                }
            }
        }
        
        # Write to file
        $output.ToString() | Out-File -FilePath $exportPath
        
        Write-Log -Message "Job info exported to $exportPath" -Level Info
        # Return the path as a single string value
        return $exportPath
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Log -Message "Failed to export job info: $errorMessage" -Level Error
        return $null
    }
}
