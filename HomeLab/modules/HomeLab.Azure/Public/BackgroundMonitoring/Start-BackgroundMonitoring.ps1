<#
.SYNOPSIS
    Starts a background monitoring job for Azure resources.
.DESCRIPTION
    Creates a background job to monitor the status of an Azure resource deployment
    without blocking the main PowerShell session. Stores job information for later retrieval.
.PARAMETER ResourceGroup
    The name of the resource group containing the resource.
.PARAMETER ResourceType
    The type of Azure resource to monitor (e.g., "vnet-gateway", "nat-gateway", "vnet").
.PARAMETER ResourceName
    The name of the resource to monitor.
.PARAMETER DeploymentName
    Optional. The name of the deployment to monitor (if monitoring a deployment).
.PARAMETER DesiredState
    Optional. The desired provisioning state to wait for. Default is "Succeeded".
.PARAMETER PollIntervalSeconds
    Optional. The interval in seconds between status checks. Default is 30 seconds.
.PARAMETER TimeoutMinutes
    Optional. Maximum time in minutes to monitor before timing out. Default is 60 minutes.
.PARAMETER CustomScriptBlock
    Optional. A custom script block to execute for monitoring. If provided, this overrides the default monitoring behavior.
.PARAMETER CustomParameters
    Optional. Parameters to pass to the custom script block.
.EXAMPLE
    Start-BackgroundMonitoring -ResourceGroup "dev-eastus-rg-homelab" -ResourceType "vnet-gateway" -ResourceName "dev-eastus-vpng-homelab"
    
    Monitors a VPN Gateway using the built-in monitoring logic.
.EXAMPLE
    Start-BackgroundMonitoring -ResourceGroup "dev-eastus-rg-homelab" -DeploymentName "network-deployment" -CustomScriptBlock { param($params) Monitor-AzDeployment $params } -CustomParameters @{ ResourceGroupName = "dev-eastus-rg-homelab"; DeploymentName = "network-deployment" }
    
    Monitors a deployment using a custom monitoring script.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Start-BackgroundMonitoring {
    [CmdletBinding(DefaultParameterSetName = "StandardMonitoring")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "StandardMonitoring")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomMonitoring")]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true, ParameterSetName = "StandardMonitoring")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomMonitoring")]
        [ValidateSet("vnet-gateway", "nat-gateway", "vnet", "deployment")]
        [string]$ResourceType,
        
        [Parameter(Mandatory = $true, ParameterSetName = "StandardMonitoring")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomMonitoring")]
        [string]$ResourceName,
        
        [Parameter(Mandatory = $false)]
        [string]$DeploymentName,
        
        [Parameter(Mandatory = $false, ParameterSetName = "StandardMonitoring")]
        [string]$DesiredState = "Succeeded",
        
        [Parameter(Mandatory = $false, ParameterSetName = "StandardMonitoring")]
        [int]$PollIntervalSeconds = 30,
        
        [Parameter(Mandatory = $false, ParameterSetName = "StandardMonitoring")]
        [int]$TimeoutMinutes = 60,
        
        [Parameter(Mandatory = $true, ParameterSetName = "CustomMonitoring")]
        [scriptblock]$CustomScriptBlock,
        
        [Parameter(Mandatory = $false, ParameterSetName = "CustomMonitoring")]
        [hashtable]$CustomParameters = @{}
    )
    
    # Create a unique job ID
    $jobId = Get-Random -Minimum 1 -Maximum 1000
    
    # Ensure the job storage directory exists
    $jobDir = Join-Path -Path $env:TEMP -ChildPath "HomeLab\Jobs"
    if (-not (Test-Path -Path $jobDir)) {
        New-Item -Path $jobDir -ItemType Directory -Force | Out-Null
    }
    
    # Create a job file path
    $jobPath = Join-Path -Path $jobDir -ChildPath "job_$jobId.xml"
    
    # Format the resource type for display
    $displayResourceType = $ResourceType
    switch ($ResourceType) {
        "vnet-gateway" { $displayResourceType = "VPN Gateway" }
        "nat-gateway" { $displayResourceType = "NAT Gateway" }
        "vnet" { $displayResourceType = "Virtual Network" }
        "deployment" { $displayResourceType = "Deployment" }
    }
    
    # If using custom monitoring, use the provided script block
    if ($PSCmdlet.ParameterSetName -eq "CustomMonitoring") {
        $scriptBlock = $CustomScriptBlock
        $scriptParameters = $CustomParameters
        
        # Ensure we have resource information for display
        if (-not $ResourceType -and $CustomParameters.ContainsKey("ResourceType")) {
            $ResourceType = $CustomParameters.ResourceType
            $displayResourceType = $ResourceType
        }
        
        if (-not $ResourceName -and $CustomParameters.ContainsKey("ResourceName")) {
            $ResourceName = $CustomParameters.ResourceName
        }
        
        if (-not $ResourceGroup -and $CustomParameters.ContainsKey("ResourceGroup")) {
            $ResourceGroup = $CustomParameters.ResourceGroup
        }
        
        if (-not $DeploymentName -and $CustomParameters.ContainsKey("DeploymentName")) {
            $DeploymentName = $CustomParameters.DeploymentName
        }
    }
    else {
        # Create the standard script block for the background job
        $scriptBlock = {
            param($ResourceGroup, $ResourceType, $ResourceName, $DesiredState, $PollIntervalSeconds, $TimeoutMinutes)
            
            # Set up command based on resource type
            switch ($ResourceType) {
                "vnet-gateway" {
                    $statusCmd = "az network vnet-gateway show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
                    $displayType = "VPN Gateway"
                }
                "nat-gateway" {
                    $statusCmd = "az network nat gateway show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
                    $displayType = "NAT Gateway"
                }
                "vnet" {
                    $statusCmd = "az network vnet show --resource-group $ResourceGroup --name $ResourceName --query provisioningState -o tsv"
                    $displayType = "Virtual Network"
                }
                "deployment" {
                    $statusCmd = "az deployment group show --resource-group $ResourceGroup --name $ResourceName --query properties.provisioningState -o tsv"
                    $displayType = "Deployment"
                }
                default {
                    $statusCmd = "az resource show --resource-group $ResourceGroup --name $ResourceName --query properties.provisioningState -o tsv"
                    $displayType = $ResourceType
                }
            }
            
            # Calculate timeout timestamp
            $startTime = Get-Date
            $timeout = $startTime.AddMinutes($TimeoutMinutes)
            
            # Create a log file in temp directory
            $logFile = Join-Path -Path $env:TEMP -ChildPath "$ResourceType-$ResourceName-monitor.log"
            
            # Initialize log
            "$(Get-Date) - Starting monitoring of $displayType '$ResourceName'" | Out-File -FilePath $logFile
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
                        "$(Get-Date) - SUCCESS: Deployment completed successfully after $formattedTime" | Out-File -FilePath $logFile -Append
                        $completed = $true
                        return @{
                            Status        = "Succeeded"
                            ElapsedTime   = $formattedTime
                            LogFile       = $logFile
                            ResourceName  = $ResourceName
                            ResourceType  = $displayType
                            ResourceGroup = $ResourceGroup
                        }
                    }
                    elseif ($currentStatus -eq "Failed") {
                        "$(Get-Date) - ✗ Deployment failed after $formattedTime" | Out-File -FilePath $logFile -Append
                        $completed = $true
                        return @{
                            Status        = "Failed"
                            ElapsedTime   = $formattedTime
                            LogFile       = $logFile
                            ResourceName  = $ResourceName
                            ResourceType  = $displayType
                            ResourceGroup = $ResourceGroup
                        }
                    }
                    
                    # Wait for next poll
                    Start-Sleep -Seconds $PollIntervalSeconds
                }
                
                # Timeout reached
                "$(Get-Date) - ⚠ Monitoring timeout reached after $TimeoutMinutes minutes" | Out-File -FilePath $logFile -Append
                return @{
                    Status        = "Timeout"
                    ElapsedTime   = $formattedTime
                    LogFile       = $logFile
                    ResourceName  = $ResourceName
                    ResourceType  = $displayType
                    ResourceGroup = $ResourceGroup
                }
            }
            catch {
                "$(Get-Date) - Error monitoring deployment: $_" | Out-File -FilePath $logFile -Append
                return @{
                    Status        = "Error"
                    ErrorMessage  = $_
                    LogFile       = $logFile
                    ResourceName  = $ResourceName
                    ResourceType  = $displayType
                    ResourceGroup = $ResourceGroup
                }
            }
        }
        
        $scriptParameters = @($ResourceGroup, $ResourceType, $ResourceName, $DesiredState, $PollIntervalSeconds, $TimeoutMinutes)
    }
    
    # Start the background job
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptParameters
    
    # Create job info object with enhanced metadata
    $jobInfo = [PSCustomObject]@{
        JobId             = $jobId
        Job               = $job
        StartTime         = [DateTime]::Now
        Command           = $scriptBlock.ToString()
        ResourceGroupName = $ResourceGroup
        ResourceType      = $displayResourceType
        ResourceName      = $ResourceName
        DeploymentName    = $DeploymentName
        Parameters        = if ($PSCmdlet.ParameterSetName -eq "CustomMonitoring") { $CustomParameters } else { @{} }
    }
    
    # Save job info
    $jobInfo | Export-Clixml -Path $jobPath
    
    # Display job information
    Write-Host "`nStarted background monitoring job with ID: $jobId" -ForegroundColor Green
    Write-Host "Resource: $displayResourceType '$ResourceName'" -ForegroundColor Cyan
    if ($DeploymentName) {
        Write-Host "Deployment: $DeploymentName" -ForegroundColor Cyan
    }
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
    Write-Host "Use 'Show-BackgroundMonitoringDetails' to check status" -ForegroundColor Yellow
    
    return $jobInfo
}
