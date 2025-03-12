<#
.SYNOPSIS
    Performs a health check on the HomeLab environment.
.DESCRIPTION
    Performs a comprehensive health check on the HomeLab environment, including resource health, connectivity, and configuration.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.EXAMPLE
    Invoke-HealthCheck -ResourceGroup "HomeLab-RG"
#>
function Invoke-HealthCheck {
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
        Write-Log -Message "Starting health check" -Level INFO
        
        # If no resource group is specified, use the one from config
        if (-not $ResourceGroup) {
            $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
        }
    }
    
    process {
        try {
            # Check if Azure is connected
            $azureConnected = Test-AzureConnection
            
            if (-not $azureConnected) {
                Write-Log -Message "Not connected to Azure. Attempting to connect..." -Level WARNING
                try {
                    Connect-AzureAccount
                    $azureConnected = $true
                }
                catch {
                    Write-Log -Message "Failed to connect to Azure: $_" -Level ERROR
                    $azureConnected = $false
                }
            }
            
            $healthResults = [PSCustomObject]@{
                OverallHealth = "Healthy"
                CheckTime = Get-Date
                Checks = @()
                Recommendations = @()
            }
            
            # Check 1: Azure Connection
            $healthResults.Checks += [PSCustomObject]@{
                Name = "Azure Connection"
                Status = if ($azureConnected) { "Healthy" } else { "Unhealthy" }
                Details = if ($azureConnected) { "Connected to Azure" } else { "Not connected to Azure" }
            }
            
            if (-not $azureConnected) {
                $healthResults.OverallHealth = "Unhealthy"
                $healthResults.Recommendations += "Connect to Azure using Connect-AzureAccount"
                return $healthResults
            }
            
            # Check 2: Resource Group Existence
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            $healthResults.Checks += [PSCustomObject]@{
                Name = "Resource Group"
                Status = if ($rgExists) { "Healthy" } else { "Unhealthy" }
                Details = if ($rgExists) { "Resource group $ResourceGroup exists" } else { "Resource group $ResourceGroup does not exist" }
            }
            
            if (-not $rgExists) {
                $healthResults.OverallHealth = "Unhealthy"
                $healthResults.Recommendations += "Create resource group $ResourceGroup"
                return $healthResults
            }
            
            # Check 3: Virtual Network
            $vnetName = "$($config.projectName)-$($config.env)-$($config.locationCode)-vnet"
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vnetName -ErrorAction SilentlyContinue
            $healthResults.Checks += [PSCustomObject]@{
                Name = "Virtual Network"
                Status = if ($vnet) { "Healthy" } else { "Unhealthy" }
                Details = if ($vnet) { "Virtual network $vnetName exists" } else { "Virtual network $vnetName does not exist" }
            }
            
            if (-not $vnet) {
                $healthResults.OverallHealth = "Unhealthy"
                $healthResults.Recommendations += "Deploy virtual network $vnetName"
            }
            
            # Check 4: VPN Gateway
            $vpnGatewayName = "$($config.projectName)-$($config.env)-$($config.locationCode)-vpngw"
            $vpnGateway = Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceGroup -Name $vpnGatewayName -ErrorAction SilentlyContinue
            $healthResults.Checks += [PSCustomObject]@{
                Name = "VPN Gateway"
                Status = if ($vpnGateway) { "Healthy" } else { "Warning" }
                Details = if ($vpnGateway) { "VPN Gateway $vpnGatewayName exists" } else { "VPN Gateway $vpnGatewayName does not exist" }
            }
            
            if (-not $vpnGateway) {
                if ($healthResults.OverallHealth -ne "Unhealthy") {
                    $healthResults.OverallHealth = "Warning"
                }
                $healthResults.Recommendations += "Deploy VPN Gateway $vpnGatewayName"
            }
            
            # Check 5: NAT Gateway
            $natGatewayName = "$($config.projectName)-$($config.env)-$($config.locationCode)-natgw"
            $natGateway = Get-AzNatGateway -ResourceGroupName $ResourceGroup -Name $natGatewayName -ErrorAction SilentlyContinue
            $healthResults.Checks += [PSCustomObject]@{
                Name = "NAT Gateway"
                Status = if ($natGateway) { "Healthy" } else { "Warning" }
                Details = if ($natGateway) { "NAT Gateway $natGatewayName exists" } else { "NAT Gateway $natGatewayName does not exist" }
            }
            
            if (-not $natGateway) {
                if ($healthResults.OverallHealth -ne "Unhealthy") {
                    $healthResults.OverallHealth = "Warning"
                }
                $healthResults.Recommendations += "Deploy NAT Gateway $natGatewayName"
            }
            
            # Check 6: Resource Health
            if ($vnet -or $vpnGateway -or $natGateway) {
                $resourceHealth = Test-ResourceHealth -ResourceGroup $ResourceGroup
                $unhealthyResources = $resourceHealth | Where-Object { $_.HealthStatus -ne "Healthy" -and $_.HealthStatus -ne "Unknown" }
                
                $healthResults.Checks += [PSCustomObject]@{
                    Name = "Resource Health"
                    Status = if ($unhealthyResources.Count -eq 0) { "Healthy" } else { "Warning" }
                    Details = if ($unhealthyResources.Count -eq 0) { "All resources are healthy" } else { "$($unhealthyResources.Count) resources are not healthy" }
                    Resources = $unhealthyResources
                }
                
                if ($unhealthyResources.Count -gt 0) {
                    if ($healthResults.OverallHealth -ne "Unhealthy") {
                        $healthResults.OverallHealth = "Warning"
                    }
                    foreach ($resource in $unhealthyResources) {
                        $healthResults.Recommendations += "Check resource $($resource.ResourceName) with health status $($resource.HealthStatus)"
                    }
                }
            }
            
            # Check 7: Configuration
            $configValid = $true
            $configIssues = @()
            
            if (-not $config.projectName) {
                $configValid = $false
                $configIssues += "Project name is not set"
            }
            
            if (-not $config.env) {
                $configValid = $false
                $configIssues += "Environment is not set"
            }
            
            if (-not $config.locationCode) {
                $configValid = $false
                $configIssues += "Location code is not set"
            }
            
            $healthResults.Checks += [PSCustomObject]@{
                Name = "Configuration"
                Status = if ($configValid) { "Healthy" } else { "Warning" }
                Details = if ($configValid) { "Configuration is valid" } else { "Configuration has issues: $($configIssues -join ', ')" }
            }
            
            if (-not $configValid) {
                if ($healthResults.OverallHealth -ne "Unhealthy") {
                    $healthResults.OverallHealth = "Warning"
                }
                $healthResults.Recommendations += "Update configuration settings"
            }
            
            return $healthResults
        }
        catch {
            Write-Log -Message "Health check failed: $_" -Level ERROR
            
            return [PSCustomObject]@{
                OverallHealth = "Error"
                CheckTime = Get-Date
                Checks = @(
                    [PSCustomObject]@{
                        Name = "Health Check Execution"
                        Status = "Error"
                        Details = "Health check failed with error: $($_.Exception.Message)"
                    }
                )
                Recommendations = @(
                    "Check logs for more details"
                )
            }
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Health check completed with status: $($healthResults.OverallHealth)" -Level INFO
    }
}

<#
.SYNOPSIS
    Gets the current health status of the HomeLab environment.
.DESCRIPTION
    Gets the current health status of the HomeLab environment from the last health check.
.EXAMPLE
    Get-HealthStatus
#>
function Get-HealthStatus {
    [CmdletBinding()]
    param ()
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Getting health status" -Level INFO
    }
    
    process {
        try {
            # Check if health status file exists
            $healthStatusPath = [System.IO.Path]::Combine($env:USERPROFILE, "HomeLab", "health_status.json")
            
            if (Test-Path -Path $healthStatusPath) {
                # Get last health check time
                $healthStatus = Get-Content -Path $healthStatusPath -Raw | ConvertFrom-Json
                $lastCheckTime = $healthStatus.CheckTime
                
                # Check if health check is older than 24 hours
                $timeSinceLastCheck = (Get-Date) - [datetime]$lastCheckTime
                
                if ($timeSinceLastCheck.TotalHours -gt 24) {
                    Write-Log -Message "Health status is more than 24 hours old. Running new health check..." -Level INFO
                    $healthStatus = Invoke-HealthCheck
                    
                    # Save updated health status
                    $healthStatus | ConvertTo-Json -Depth 5 | Out-File -FilePath $healthStatusPath -Encoding utf8
                }
                
                return $healthStatus
            }
            else {
                Write-Log -Message "No health status found. Running health check..." -Level INFO
                
                # Run health check
                $healthStatus = Invoke-HealthCheck
                
                # Create directory if it doesn't exist
                $healthStatusDir = [System.IO.Path]::GetDirectoryName($healthStatusPath)
                if (-not (Test-Path -Path $healthStatusDir -PathType Container)) {
                    New-Item -Path $healthStatusDir -ItemType Directory -Force | Out-Null
                }
                
                # Save health status
                $healthStatus | ConvertTo-Json -Depth 5 | Out-File -FilePath $healthStatusPath -Encoding utf8
                
                return $healthStatus
            }
        }
        catch {
            Write-Log -Message "Failed to get health status: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Health status retrieved" -Level INFO
    }
}

<#
.SYNOPSIS
    Exports a health report to a file.
.DESCRIPTION
    Exports a health report to a file in the specified format.
.PARAMETER Path
    The path where the report will be saved. If not specified, the report will be saved to the user's Documents folder.
.PARAMETER Format
    The format of the report. Valid values are 'HTML', 'JSON', 'TXT'. Default is 'HTML'.
.EXAMPLE
    Export-HealthReport -Path "C:\Reports" -Format "HTML"
#>
function Export-HealthReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'JSON', 'TXT')]
        [string]$Format = 'HTML'
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Exporting health report" -Level INFO
        
        # Set default path if not specified
        if (-not $Path) {
            $Path = [System.IO.Path]::Combine([Environment]::GetFolderPath('MyDocuments'), 'HomeLab', 'Reports')
        }
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $Path -PathType Container)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
    }
    
    process {
        try {
            # Get health status
            $healthStatus = Get-HealthStatus
            
            # Generate filename
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "HealthReport_${timestamp}"
            
            # Export based on format
            switch ($Format) {
                'HTML' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.html")
                    
                    # Create HTML report
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>HomeLab Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e6f2ff; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .healthy { color: green; }
        .warning { color: orange; }
        .unhealthy { color: red; }
        .error { color: darkred; }
    </style>
</head>
<body>
    <h1>HomeLab Health Report</h1>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Overall Health:</strong> <span class="$($healthStatus.OverallHealth.ToLower())">$($healthStatus.OverallHealth)</span></p>
        <p><strong>Check Time:</strong> $($healthStatus.CheckTime)</p>
    </div>
    
    <h2>Health Checks</h2>
    <table>
        <tr>
            <th>Check</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
"@

                    # Add rows for health checks
                    foreach ($check in $healthStatus.Checks) {
                        $statusClass = $check.Status.ToLower()
                        $html += @"
        <tr>
            <td>$($check.Name)</td>
            <td class="$statusClass">$($check.Status)</td>
            <td>$($check.Details)</td>
        </tr>
"@
                    }
                    
                    $html += @"
    </table>
    
    <h2>Recommendations</h2>
    <ul>
"@

                    # Add recommendations
                    if ($healthStatus.Recommendations.Count -gt 0) {
                        foreach ($recommendation in $healthStatus.Recommendations) {
                            $html += @"
        <li>$recommendation</li>
"@
                        }
                    }
                    else {
                        $html += @"
        <li>No recommendations at this time.</li>
"@
                    }
                    
                    $html += @"
    </ul>
    
    <p><em>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
</body>
</html>
"@
                    
                    # Save HTML to file
                    $html | Out-File -FilePath $filePath -Encoding utf8
                }
                'JSON' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.json")
                    $healthStatus | ConvertTo-Json -Depth 5 | Out-File -FilePath $filePath -Encoding utf8
                }
                'TXT' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.txt")
                    
                    $txt = @"
HomeLab Health Report
=====================

Summary
-------
Overall Health: $($healthStatus.OverallHealth)
Check Time: $($healthStatus.CheckTime)

Health Checks
------------
"@
                    
                    foreach ($check in $healthStatus.Checks) {
                        $txt += @"

Check: $($check.Name)
Status: $($check.Status)
Details: $($check.Details)
"@
                    }
                    
                    $txt += @"

Recommendations
--------------
"@
                    
                    if ($healthStatus.Recommendations.Count -gt 0) {
                        foreach ($recommendation in $healthStatus.Recommendations) {
                            $txt += @"
- $recommendation
"@
                        }
                    }
                    else {
                        $txt += @"
- No recommendations at this time.
"@
                    }
                    
                    $txt += @"

Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
                    
                    # Save TXT to file
                    $txt | Out-File -FilePath $filePath -Encoding utf8
                }
            }
            
            Write-Log -Message "Health report exported to $filePath" -Level INFO
            return $filePath
        }
        catch {
            Write-Log -Message "Failed to export health report: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Health report export completed" -Level INFO
    }
}
