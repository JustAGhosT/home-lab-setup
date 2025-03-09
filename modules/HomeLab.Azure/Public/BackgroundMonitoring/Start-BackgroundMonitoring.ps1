<#
.SYNOPSIS
    Starts a background monitoring job for Azure resources.
.DESCRIPTION
    Creates a background job to monitor the status of an Azure resource deployment
    without blocking the main PowerShell session.
.PARAMETER ResourceGroup
    The name of the resource group containing the resource.
.PARAMETER ResourceType
    The type of Azure resource to monitor (e.g., "vnet-gateway", "nat-gateway").
.PARAMETER ResourceName
    The name of the resource to monitor.
.PARAMETER DesiredState
    Optional. The desired provisioning state to wait for. Default is "Succeeded".
.PARAMETER PollIntervalSeconds
    Optional. The interval in seconds between status checks. Default is 30 seconds.
.PARAMETER TimeoutMinutes
    Optional. Maximum time in minutes to monitor before timing out. Default is 60 minutes.
.EXAMPLE
    Start-BackgroundMonitoring -ResourceGroup "dev-eastus-rg-homelab" -ResourceType "vnet-gateway" -ResourceName "dev-eastus-vpng-homelab"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Start-BackgroundMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("vnet-gateway", "nat-gateway", "vnet")]
        [string]$ResourceType,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory=$false)]
        [string]$DesiredState = "Succeeded",
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 30,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMinutes = 60
    )
    
    # Create a unique job name
    $jobName = "Monitor_${ResourceType}_${ResourceName}_$(Get-Random)"
    
    # Create the script block for the background job
    $scriptBlock = {
        param($ResourceGroup, $ResourceType, $ResourceName, $DesiredState, $PollIntervalSeconds, $TimeoutMinutes)
        
        # Set up command based on resource type
        switch ($ResourceType) {
            "vnet-gateway" {
                $statusCmd = "az network vnet-gateway show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
            }
            "nat-gateway" {
                $statusCmd = "az network nat gateway show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
            }
            "vnet" {
                $statusCmd = "az network vnet show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
            }
        }
        
        # Calculate timeout timestamp
        $startTime = Get-Date
        $timeout = $startTime.AddMinutes($TimeoutMinutes)
        
        # Create a log file in temp directory
        $logFile = Join-Path -Path $env:TEMP -ChildPath "$ResourceType-$ResourceName-monitor.log"
        
        # Initialize log
        "$(Get-Date) - Starting monitoring of $ResourceType '$ResourceName'" | Out-File -FilePath $logFile
        "$(Get-Date) - Target state: $DesiredState, Timeout: $TimeoutMinutes minutes" | Out-File -FilePath $logFile -Append
        
        $lastStatus = ""
        $completed = $false
        
        try {
            while ((Get-Date) -lt $timeout -and -not $completed) {
                # Execute the status command
                $currentStatus = Invoke-Expression $statusCmd 2>$null
                $elapsedTime = (Get-Date) - $startTime
                $formattedTime = "{0:hh\:mm\:ss}" -f $elapsedTime
                
                # Log status changes
                if ($currentStatus -ne $lastStatus) {
                    "$(Get-Date) - Status changed to: $currentStatus (Elapsed: $formattedTime)" | Out-File -FilePath $logFile -Append
                    $lastStatus = $currentStatus
                }
                
                # Check if deployment has completed or failed
                if ($currentStatus -eq $DesiredState) {
                    "$(Get-Date) - ✓ Deployment completed successfully after $formattedTime" | Out-File -FilePath $logFile -Append
                    $completed = $true
                    return @{
                        Status = "Succeeded"
                        ElapsedTime = $formattedTime
                        LogFile = $logFile
                        ResourceName = $ResourceName
                        ResourceType = $ResourceType
                    }
                }
                elseif ($currentStatus -eq "Failed") {
                    "$(Get-Date) - ✗ Deployment failed after $formattedTime" | Out-File -FilePath $logFile -Append
                    $completed = $true
                    return @{
                        Status = "Failed"
                        ElapsedTime = $formattedTime
                        LogFile = $logFile
                        ResourceName = $ResourceName
                        ResourceType = $ResourceType
                    }
                }
                
                # Wait for next poll
                Start-Sleep -Seconds $PollIntervalSeconds
            }
            
            # Timeout reached
            "$(Get-Date) - ⚠ Monitoring timeout reached after $TimeoutMinutes minutes" | Out-File -FilePath $logFile -Append
            return @{
                Status = "Timeout"
                ElapsedTime = $formattedTime
                LogFile = $logFile
                ResourceName = $ResourceName
                ResourceType = $ResourceType
            }
        }
        catch {
            "$(Get-Date) - Error monitoring deployment: $_" | Out-File -FilePath $logFile -Append
            return @{
                Status = "Error"
                ErrorMessage = $_
                LogFile = $logFile
                ResourceName = $ResourceName
                ResourceType = $ResourceType
            }
        }
    }
    
    # Start the background job
    $job = Start-Job -Name $jobName -ScriptBlock $scriptBlock -ArgumentList $ResourceGroup, $ResourceType, $ResourceName, $DesiredState, $PollIntervalSeconds, $TimeoutMinutes
    
    # Return information about the job
    return @{
        JobName = $jobName
        JobId = $job.Id
        ResourceType = $ResourceType
        ResourceName = $ResourceName
        StartTime = Get-Date
    }
}

