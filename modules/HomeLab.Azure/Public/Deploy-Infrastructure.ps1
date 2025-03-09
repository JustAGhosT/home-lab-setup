<#
.SYNOPSIS
    Deploys Azure infrastructure for HomeLab.
.DESCRIPTION
    Retrieves global configuration and deploys either the full infrastructure or a specific component
    (network, VPN gateway, or NAT gateway) using the corresponding Bicep templates.
.PARAMETER ComponentsOnly
    Optional. Specifies a single component to deploy ("network", "vpngateway", or "natgateway").
    If not specified, all components will be deployed.
.PARAMETER ResourceGroup
    Optional. The name of the resource group to deploy to. If not provided, it will be constructed from configuration.
.PARAMETER Force
    Optional. If specified, skips confirmation prompts during deployment.
.PARAMETER Monitor
    Optional. If specified, monitors the deployment until completion.
.PARAMETER BackgroundMonitor
    Optional. If specified, starts a background monitoring job instead of blocking the console.
.EXAMPLE
    Deploy-Infrastructure -ComponentsOnly "network"
.EXAMPLE
    Deploy-Infrastructure -Force -BackgroundMonitor
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Deploy-Infrastructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("network", "vpngateway", "natgateway")]
        [string]$ComponentsOnly,
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force,
        
        [Parameter(Mandatory=$false)]
        [switch]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [switch]$BackgroundMonitor
    )
    
    # Ensure we're connected to Azure
    if (-not (Connect-AzureAccount)) {
        Write-Log -Message "Failed to connect to Azure. Deployment aborted." -Level Error
        return $false
    }
    
    # Retrieve global configuration
    $config = Get-Configuration
    $env = $config.env
    $loc = $config.loc
    $project = $config.project
    $location = $config.location
    
    # Construct the resource group name if not provided
    if (-not $ResourceGroup) {
        $ResourceGroup = "$env-$loc-rg-$project"
    }
    
    # Check if resource group exists, create if it doesn't
    if (-not (Test-ResourceGroup -ResourceGroupName $ResourceGroup)) {
        Write-Log -Message "Creating resource group '$ResourceGroup' in location '$location'..." -Level Info
        $result = az group create --name $ResourceGroup --location $location
        if (-not $?) {
            Write-Log -Message "Failed to create resource group. Deployment aborted." -Level Error
            return $false
        }
    }
    
    # Get the templates path
    $templatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
    
    Write-Log -Message "Starting deployment for resource group: $ResourceGroup" -Level Info
    
    # Common parameters for all deployments
    $commonParams = @(
        "--resource-group", $ResourceGroup,
        "--parameters", "location=$location", "env=$env", "loc=$loc", "project=$project"
    )
    
    # Add confirmation parameter if not forcing
    if (-not $Force) {
        $commonParams += "--confirm-with-what-if"
    }
    
    # Add no-wait parameter if monitoring (we'll monitor the deployment separately)
    if ($Monitor -or $BackgroundMonitor) {
        $commonParams += "--no-wait"
    }
    
    # Deploy the specified component or all components
    if ($ComponentsOnly -eq "network") {
        Write-Log -Message "Deploying network resources using network.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $templateFile) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $result = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "Network deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # If monitoring is enabled, monitor the virtual network deployment
        $vnetName = "$env-$loc-vnet-$project"
        
        if ($Monitor) {
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "vnet" -ResourceName $vnetName -PollIntervalSeconds 10
            
            if (-not $monitorResult) {
                Write-Log -Message "Network deployment monitoring failed or timed out" -Level Warning
                return $false
            }
        }
        elseif ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet" -ResourceName $vnetName -PollIntervalSeconds 10
            Write-Log -Message "Background monitoring started for Virtual Network (Job ID: $($job.JobId))" -Level Info
        }
        
        Write-Log -Message "Network deployment initiated successfully" -Level Success
    }
    elseif ($ComponentsOnly -eq "vpngateway") {
        Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $templateFile) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $result = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "VPN gateway deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # If monitoring is enabled, monitor the VPN gateway deployment
        $vpnGatewayName = "$env-$loc-vpng-$project"
        
        if ($Monitor) {
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $vpnGatewayName -PollIntervalSeconds 30 -TimeoutMinutes 60
            
            if (-not $monitorResult) {
                Write-Log -Message "VPN gateway deployment monitoring failed or timed out" -Level Warning
                return $false
            }
        }
        elseif ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $vpnGatewayName -PollIntervalSeconds 30 -TimeoutMinutes 60
            Write-Log -Message "Background monitoring started for VPN Gateway (Job ID: $($job.JobId))" -Level Info
        }
        
        Write-Log -Message "VPN gateway deployment initiated successfully" -Level Success
    }
    elseif ($ComponentsOnly -eq "natgateway") {
        Write-Log -Message "Deploying NAT gateway using nat-gateway.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $templateFile) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $result = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "NAT gateway deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # If monitoring is enabled, monitor the NAT gateway deployment
        $natGatewayName = "$env-$loc-natgw-$project"
        
        if ($Monitor) {
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "nat-gateway" -ResourceName $natGatewayName -PollIntervalSeconds 10
            
            if (-not $monitorResult) {
                Write-Log -Message "NAT gateway deployment monitoring failed or timed out" -Level Warning
                return $false
            }
        }
        elseif ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "nat-gateway" -ResourceName $natGatewayName -PollIntervalSeconds 10
            Write-Log -Message "Background monitoring started for NAT Gateway (Job ID: $($job.JobId))" -Level Info
        }
        
        Write-Log -Message "NAT gateway deployment initiated successfully" -Level Success
    }
    else {
        Write-Log -Message "Deploying full infrastructure: Network, VPN Gateway, and NAT Gateway" -Level Info
        
        # Deploy network resources
        $networkTemplate = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        Write-Log -Message "Deploying network using $networkTemplate" -Level Info
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $networkTemplate) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $resultNetwork = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "Network deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # Start monitoring for network if requested
        $vnetName = "$env-$loc-vnet-$project"
        if ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet" -ResourceName $vnetName -PollIntervalSeconds 10
            Write-Log -Message "Background monitoring started for Virtual Network (Job ID: $($job.JobId))" -Level Info
        }
        
        # Deploy VPN gateway
        $vpnTemplate = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        Write-Log -Message "Deploying VPN gateway using $vpnTemplate" -Level Info
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $vpnTemplate) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $resultVpn = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "VPN gateway deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # Start monitoring for VPN Gateway if requested
        $vpnGatewayName = "$env-$loc-vpng-$project"
        if ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $vpnGatewayName -PollIntervalSeconds 30 -TimeoutMinutes 60
            Write-Log -Message "Background monitoring started for VPN Gateway (Job ID: $($job.JobId))" -Level Info
        }
        
        # Deploy NAT gateway
        $natTemplate = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        Write-Log -Message "Deploying NAT gateway using $natTemplate" -Level Info
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $natTemplate) + $commonParams
        
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        $resultNat = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if (!($Monitor -or $BackgroundMonitor) -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "NAT gateway deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # Start monitoring for NAT Gateway if requested
        $natGatewayName = "$env-$loc-natgw-$project"
        if ($BackgroundMonitor) {
            $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "nat-gateway" -ResourceName $natGatewayName -PollIntervalSeconds 10
            Write-Log -Message "Background monitoring started for NAT Gateway (Job ID: $($job.JobId))" -Level Info
        }
        
        # If foreground monitoring is requested, monitor each component sequentially
        if ($Monitor) {
            Write-Log -Message "Monitoring network deployment..." -Level Info
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "vnet" -ResourceName $vnetName -PollIntervalSeconds 10
            
            Write-Log -Message "Monitoring VPN Gateway deployment..." -Level Info
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $vpnGatewayName -PollIntervalSeconds 30 -TimeoutMinutes 60
            
            Write-Log -Message "Monitoring NAT Gateway deployment..." -Level Info
            $monitorResult = Monitor-AzureResourceDeployment -ResourceGroup $ResourceGroup -ResourceType "nat-gateway" -ResourceName $natGatewayName -PollIntervalSeconds 10
        }
    }
    
    Write-Log -Message "Deployment initiated successfully." -Level Success
    return $true
}
