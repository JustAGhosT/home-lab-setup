<#
.SYNOPSIS
    Monitors the status of an Azure resource with a timer.
.DESCRIPTION
    Polls an Azure resource at regular intervals and displays its current status
    along with elapsed time until it reaches the desired state.
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
    Monitor-AzureResourceDeployment -ResourceGroup "dev-eastus-rg-homelab" -ResourceType "vnet-gateway" -ResourceName "dev-eastus-vpng-homelab"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Monitor-AzureResourceDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("vnet-gateway", "nat-gateway", "vnet")]
        [string]$ResourceType,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory = $false)]
        [string]$DesiredState = "Succeeded",
        
        [Parameter(Mandatory = $false)]
        [int]$PollIntervalSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMinutes = 60
    )
    
    # Calculate timeout timestamp
    $startTime = Get-Date
    $timeout = $startTime.AddMinutes($TimeoutMinutes)
    $elapsedTime = [TimeSpan]::Zero
    
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
    
    Write-ColorOutput "Starting deployment monitoring for $ResourceType '$ResourceName'..." -ForegroundColor Cyan
    Write-ColorOutput "This may take some time. Press Ctrl+C to stop monitoring (deployment will continue in background)." -ForegroundColor Yellow
    
    $lastStatus = ""
    $statusChanged = $false
    $spinner = @('|', '/', '-', '\')
    $spinnerIndex = 0
    
    try {
        while ((Get-Date) -lt $timeout) {
            # Clear the current line
            Write-Host "`r" -NoNewline
            
            # Execute the status command
            $currentStatus = Invoke-Expression $statusCmd 2>$null
            $elapsedTime = (Get-Date) - $startTime
            $formattedTime = "{0:hh\:mm\:ss}" -f $elapsedTime
            
            # Update spinner
            $spinnerChar = $spinner[$spinnerIndex % $spinner.Length]
            $spinnerIndex++
            
            # Check if status has changed
            if ($currentStatus -ne $lastStatus) {
                $statusChanged = $true
                $lastStatus = $currentStatus
            }
            
            # Display status with elapsed time and spinner
            $statusColor = switch ($currentStatus) {
                $DesiredState { "Green" }
                "Failed" { "Red" }
                default { "Yellow" }
            }
            
            # Display status line
            Write-Host "$spinnerChar Monitoring $ResourceType '$ResourceName' | Status: " -NoNewline
            Write-Host $currentStatus -ForegroundColor $statusColor -NoNewline
            Write-Host " | Elapsed: $formattedTime" -NoNewline
            
            # Check if deployment has completed or failed
            if ($currentStatus -eq $DesiredState) {
                Write-Host ""  # Add a newline
                Write-ColorOutput "SUCCESS: Deployment of $ResourceType '$ResourceName' completed successfully after $formattedTime" -ForegroundColor Green
                return $true
            }
            elseif ($currentStatus -eq "Failed") {
                Write-Host ""  # Add a newline
                Write-ColorOutput "ERROR: Deployment of $ResourceType '$ResourceName' failed after $formattedTime" -ForegroundColor Red
                return $false
            }
            
            # Wait for next poll
            Start-Sleep -Seconds $PollIntervalSeconds
        }
        
        # Timeout reached
        Write-Host ""  # Add a newline
        Write-ColorOutput "⚠ Monitoring timeout reached after $TimeoutMinutes minutes. Deployment may still be in progress." -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Host ""  # Add a newline
        if (Get-Command Write-ColorOutput -ErrorAction SilentlyContinue) {
            Write-ColorOutput "Error monitoring deployment: $($_.Exception.Message)" -ForegroundColor Red
        }
        else {
            Write-Host "Error monitoring deployment: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}
