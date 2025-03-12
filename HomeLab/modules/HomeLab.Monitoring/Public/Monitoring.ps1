<#
.SYNOPSIS
    Starts monitoring Azure resources.
.DESCRIPTION
    Starts monitoring Azure resources by setting up a background job that collects metrics at regular intervals.
.PARAMETER ResourceGroup
    The name of the resource group to monitor. If not specified, all resources in the subscription will be monitored.
.PARAMETER IntervalMinutes
    The interval in minutes at which to collect metrics. Default is 15 minutes.
.EXAMPLE
    Start-ResourceMonitoring -ResourceGroup "HomeLab-RG" -IntervalMinutes 5
#>
function Start-ResourceMonitoring {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 15
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Starting resource monitoring" -Level INFO
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # If no resource group is specified, use the one from config
            if (-not $ResourceGroup) {
                $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
            }
            
            # Check if the resource group exists
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $rgExists) {
                throw "Resource group $ResourceGroup does not exist"
            }
            
            # Start a background job to monitor resources
            $jobScript = {
                param($ResourceGroup, $IntervalMinutes, $ConfigPath)
                
                # Import required modules
                Import-Module HomeLab.Core
                Import-Module HomeLab.Azure
                Import-Module Az.Monitor
                
                # Load configuration
                Initialize-Configuration -Path $ConfigPath
                
                while ($true) {
                    try {
                        # Get all resources in the resource group
                        $resources = Get-AzResource -ResourceGroupName $ResourceGroup
                        
                        foreach ($resource in $resources) {
                            # Get metrics for the resource
                            $metrics = Get-AzMetric -ResourceId $resource.Id -MetricName "Percentage CPU" -TimeGrain 00:05:00 -DetailedOutput
                            
                            # Log the metrics
                            Write-Log -Message "Resource: $($resource.Name), Type: $($resource.ResourceType), CPU: $($metrics.Data.Average)" -Level INFO
                            
                            # Check if metrics exceed thresholds and trigger alerts if needed
                            if ($metrics.Data.Average -gt 80) {
                                Write-Log -Message "HIGH CPU ALERT: Resource $($resource.Name) has CPU usage of $($metrics.Data.Average)%" -Level WARNING
                                # TODO: Implement alerting mechanism
                            }
                        }
                    }
                    catch {
                        Write-Log -Message "Error monitoring resources: $_" -Level ERROR
                    }
                    
                    # Wait for the specified interval
                    Start-Sleep -Seconds ($IntervalMinutes * 60)
                }
            }
            
            # Start the background job
            $job = Start-Job -ScriptBlock $jobScript -ArgumentList $ResourceGroup, $IntervalMinutes, $config.configPath
            
            # Store the job ID in the configuration
            $config.monitoringJobId = $job.Id
            Save-Configuration
            
            Write-Log -Message "Resource monitoring started with job ID $($job.Id)" -Level INFO
            return $job
        }
        catch {
            Write-Log -Message "Failed to start resource monitoring: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Resource monitoring setup completed" -Level INFO
    }
}

<#
.SYNOPSIS
    Gets performance metrics for Azure resources.
.DESCRIPTION
    Gets performance metrics for Azure resources in the specified resource group.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.PARAMETER ResourceType
    The type of resource to get metrics for. If not specified, all resource types will be included.
.PARAMETER TimeGrain
    The time grain for the metrics. Default is 1 hour.
.PARAMETER StartTime
    The start time for the metrics. Default is 24 hours ago.
.PARAMETER EndTime
    The end time for the metrics. Default is the current time.
.EXAMPLE
    Get-ResourceMetrics -ResourceGroup "HomeLab-RG" -ResourceType "Microsoft.Compute/virtualMachines"
#>
function Get-ResourceMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $false)]
        [string]$ResourceType,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeGrain = "01:00:00",
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartTime = (Get-Date).AddHours(-24),
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndTime = (Get-Date)
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Getting resource metrics" -Level INFO
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # If no resource group is specified, use the one from config
            if (-not $ResourceGroup) {
                $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
            }
            
            # Get resources based on the specified filters
            $resourceFilter = @{
                ResourceGroupName = $ResourceGroup
            }
            
            if ($ResourceType) {
                $resourceFilter.ResourceType = $ResourceType
            }
            
            $resources = Get-AzResource @resourceFilter
            
            $results = @()
            
            foreach ($resource in $resources) {
                # Get available metrics for the resource
                $availableMetrics = Get-AzMetricDefinition -ResourceId $resource.Id
                
                # Get common metrics based on resource type
                $metricsToGet = @()
                
                switch -Wildcard ($resource.ResourceType) {
                    "Microsoft.Compute/virtualMachines" {
                        $metricsToGet = @("Percentage CPU", "Available Memory Bytes", "Disk Read Bytes", "Disk Write Bytes", "Network In", "Network Out")
                    }
                    "Microsoft.Network/virtualNetworkGateways" {
                        $metricsToGet = @("AverageBandwidth", "P2SBandwidth", "P2SConnectionCount", "TunnelEgressBytes", "TunnelIngressBytes")
                    }
                    "Microsoft.Network/natGateways" {
                        $metricsToGet = @("ByteCount", "PacketCount", "DroppedPacketCount")
                    }
                    default {
                        # For other resource types, just get the first 3 available metrics
                        $metricsToGet = $availableMetrics | Select-Object -First 3 | ForEach-Object { $_.Name.Value }
                    }
                }
                
                # Filter metrics to only those that are available for the resource
                $availableMetricNames = $availableMetrics | ForEach-Object { $_.Name.Value }
                $metricsToGet = $metricsToGet | Where-Object { $_ -in $availableMetricNames }
                
                $resourceMetrics = @{
                    ResourceName = $resource.Name
                    ResourceType = $resource.ResourceType
                    Metrics = @{}
                }
                
                foreach ($metricName in $metricsToGet) {
                    $metric = Get-AzMetric -ResourceId $resource.Id -MetricName $metricName -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime -DetailedOutput
                    
                    $metricData = @{
                        Name = $metricName
                        Unit = $metric.Unit
                        Data = $metric.Data | Select-Object TimeStamp, Average, Minimum, Maximum
                    }
                    
                    $resourceMetrics.Metrics[$metricName] = $metricData
                }
                
                $results += $resourceMetrics
            }
            
            return $results
        }
        catch {
            Write-Log -Message "Failed to get resource metrics: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Resource metrics retrieved successfully" -Level INFO
    }
}

<#
.SYNOPSIS
    Tests the health of Azure resources.
.DESCRIPTION
    Tests the health of Azure resources in the specified resource group.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.EXAMPLE
    Test-ResourceHealth -ResourceGroup "HomeLab-RG"
#>
function Test-ResourceHealth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Testing resource health" -Level INFO
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # If no resource group is specified, use the one from config
            if (-not $ResourceGroup) {
                $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
            }
            
            # Get all resources in the resource group
            $resources = Get-AzResource -ResourceGroupName $ResourceGroup
            
            $healthResults = @()
            
            foreach ($resource in $resources) {
                try {
                    # Get resource health
                    $health = Get-AzHealthResource -ResourceId $resource.Id -ErrorAction SilentlyContinue
                    
                    if ($health) {
                        $healthStatus = $health.Properties.availabilityState
                    }
                    else {
                        $healthStatus = "Unknown"
                    }
                    
                    # Get additional status information based on resource type
                    $statusInfo = $null
                    
                    switch -Wildcard ($resource.ResourceType) {
                        "Microsoft.Compute/virtualMachines" {
                            $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $resource.Name -Status
                            $statusInfo = $vm.Statuses | Where-Object { $_.Code -like "PowerState*" } | ForEach-Object { $_.DisplayStatus }
                        }
                        "Microsoft.Network/virtualNetworkGateways" {
                            $gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceGroup -Name $resource.Name
                            $statusInfo = $gateway.ProvisioningState
                        }
                        "Microsoft.Network/natGateways" {
                            $natGateway = Get-AzNatGateway -ResourceGroupName $ResourceGroup -Name $resource.Name
                            $statusInfo = $natGateway.ProvisioningState
                        }
                        default {
                            $statusInfo = "Not available"
                        }
                    }
                    
                    $healthResults += [PSCustomObject]@{
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        HealthStatus = $healthStatus
                        StatusInfo = $statusInfo
                        LastUpdated = Get-Date
                    }
                }
                catch {
                    Write-Log -Message "Failed to get health for resource $($resource.Name): $_" -Level WARNING
                    
                    $healthResults += [PSCustomObject]@{
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        HealthStatus = "Error"
                        StatusInfo = $_.Exception.Message
                        LastUpdated = Get-Date
                    }
                }
            }
            
            return $healthResults
        }
        catch {
            Write-Log -Message "Failed to test resource health: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Resource health test completed" -Level INFO
    }
}
