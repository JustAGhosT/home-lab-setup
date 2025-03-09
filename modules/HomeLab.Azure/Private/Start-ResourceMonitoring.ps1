<#
.SYNOPSIS
    Monitors Azure resource deployment status.
.DESCRIPTION
    Monitors the provisioning state of an Azure resource, either synchronously or in a background job.
.PARAMETER ResourceGroup
    The name of the resource group containing the resource.
.PARAMETER ResourceType
    The Azure resource type.
.PARAMETER ResourceName
    The name of the resource to monitor.
.PARAMETER PollIntervalSeconds
    The interval in seconds between status checks.
.PARAMETER TimeoutMinutes
    The maximum time in minutes to monitor before timing out.
.PARAMETER BackgroundJob
    If specified, monitoring runs in a background job.
.EXAMPLE
    Start-ResourceMonitoring -ResourceGroup "myRG" -ResourceType "Microsoft.Network/virtualNetworks" -ResourceName "myVNet" -BackgroundJob
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Start-ResourceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceType,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 30,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMinutes = 60,
        
        [Parameter(Mandatory=$false)]
        [switch]$BackgroundJob
    )
    
    if ($BackgroundJob) {
        # Create a log file for this monitoring session
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFile = Join-Path -Path $env:TEMP -ChildPath "Monitor_${ResourceType}_${timestamp}.log"
        
        # Create a script block for the monitoring job
        $monitorScriptBlock = {
            param($ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes, $LogFile)
            
            # Simple logging function for the background job
            function Write-MonitorLog {
                param(
                    [Parameter(Mandatory=$true)]
                    [string]$Message,
                    
                    [Parameter(Mandatory=$false)]
                    [string]$Level = "Info"
                )
                
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logEntry = "[$timestamp] [$Level] $Message"
                Write-Output $logEntry
                $logEntry | Out-File -FilePath $LogFile -Append
            }
            
            Write-MonitorLog "Starting monitoring for $ResourceType '$ResourceName' in resource group '$ResourceGroup'"
            
            $startTime = Get-Date
            $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
            $completed = $false
            $status = "Unknown"
            
            while (-not $completed -and (Get-Date) -lt $timeout) {
                try {
                    # Use az CLI to check resource status
                    $status = az resource show --resource-group $ResourceGroup --name $ResourceName --resource-type $ResourceType --query "properties.provisioningState" -o tsv 2>$null
                    
                    if ($status) {
                        Write-MonitorLog "Current status: $status"
                        
                        if ($status -eq "Succeeded") {
                            Write-MonitorLog "Resource provisioning completed successfully." -Level "Success"
                            $completed = $true
                        }
                        elseif ($status -eq "Failed") {
                            Write-MonitorLog "Resource provisioning failed." -Level "Error"
                            $completed = $true
                        }
                        elseif ($status -eq "Canceled") {
                            Write-MonitorLog "Resource provisioning was canceled." -Level "Warning"
                            $completed = $true
                        }
                        else {
                            # Still in progress, wait for the next poll
                            Write-MonitorLog "Resource provisioning in progress. Waiting $PollIntervalSeconds seconds..."
                            Start-Sleep -Seconds $PollIntervalSeconds
                        }
                    }
                    else {
                        Write-MonitorLog "Could not retrieve resource status. Resource may not exist yet." -Level "Warning"
                        Start-Sleep -Seconds $PollIntervalSeconds
                    }
                }
                catch {
                    Write-MonitorLog "Error checking resource status: $_" -Level "Error"
                    Start-Sleep -Seconds $PollIntervalSeconds
                }
            }
            
            if (-not $completed) {
                Write-MonitorLog "Monitoring timed out after $TimeoutMinutes minutes." -Level "Warning"
            }
            
            $duration = (Get-Date) - $startTime
            Write-MonitorLog "Monitoring completed. Total duration: $($duration.TotalMinutes.ToString('0.00')) minutes" -Level "Info"
            
            return @{
                ResourceGroup = $ResourceGroup
                ResourceType = $ResourceType
                ResourceName = $ResourceName
                Completed = $completed
                FinalStatus = $status
                Duration = $duration.TotalMinutes.ToString('0.00')
                LogFile = $LogFile
                StartTime = $startTime
                EndTime = Get-Date
            }
        }
        
        # Start the monitoring job
        $monitorJobName = "Monitor_${ResourceType}_$(Get-Random)"
        $monitorJob = Start-Job -Name $monitorJobName -ScriptBlock $monitorScriptBlock -ArgumentList $ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes, $logFile
        
        Write-Log "Started background monitoring job '$monitorJobName' (ID: $($monitorJob.Id)) for $ResourceType '$ResourceName'" -Level Info
        Write-Log "Monitoring log file: $logFile" -Level Info
        
        return @{
            JobId = $monitorJob.Id
            JobName = $monitorJobName
            LogFile = $logFile
            ResourceGroup = $ResourceGroup
            ResourceType = $ResourceType
            ResourceName = $ResourceName
            StartTime = Get-Date
        }
    }
    else {
        # Synchronous monitoring
        Write-Log "Starting synchronous monitoring for $ResourceType '$ResourceName' in resource group '$ResourceGroup'" -Level Info
        
        $startTime = Get-Date
        $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
        $completed = $false
        $status = "Unknown"
        
        while (-not $completed -and (Get-Date) -lt $timeout) {
            try {
                # Use az CLI to check resource status
                $status = az resource show --resource-group $ResourceGroup --name $ResourceName --resource-type $ResourceType --query "properties.provisioningState" -o tsv 2>$null
                
                if ($status) {
                    Write-Log "Current status: $status" -Level Info
                    
                    if ($status -eq "Succeeded") {
                        Write-Log "Resource provisioning completed successfully." -Level Success
                        $completed = $true
                    }
                    elseif ($status -eq "Failed") {
                        Write-Log "Resource provisioning failed." -Level Error
                        $completed = $true
                    }
                    elseif ($status -eq "Canceled") {
                        Write-Log "Resource provisioning was canceled." -Level Warning
                        $completed = $true
                    }
                    else {
                        # Still in progress, wait for the next poll
                        Write-Log "Resource provisioning in progress. Waiting $PollIntervalSeconds seconds..." -Level Info -NoNewLine
                        Start-Sleep -Seconds $PollIntervalSeconds
                        Write-Host "`r                                                                      `r" -NoNewline
                    }
                }
                else {
                    Write-Log "Could not retrieve resource status. Resource may not exist yet." -Level Warning
                    Start-Sleep -Seconds $PollIntervalSeconds
                }
            }
            catch {
                Write-Log "Error checking resource status: $_" -Level Error
                Start-Sleep -Seconds $PollIntervalSeconds
            }
        }
        
        if (-not $completed) {
            Write-Log "Monitoring timed out after $TimeoutMinutes minutes." -Level Warning
        }
        
        $duration = (Get-Date) - $startTime
        Write-Log "Monitoring completed. Total duration: $($duration.TotalMinutes.ToString('0.00')) minutes" -Level Info
        
        return @{
            ResourceGroup = $ResourceGroup
            ResourceType = $ResourceType
            ResourceName = $ResourceName
            Completed = $completed
            FinalStatus = $status
            Duration = $duration.TotalMinutes.ToString('0.00')
            StartTime = $startTime
            EndTime = Get-Date
        }
    }
}