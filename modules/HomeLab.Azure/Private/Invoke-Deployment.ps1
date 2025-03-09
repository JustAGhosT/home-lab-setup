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
.EXAMPLE
    Deploy-Infrastructure -ComponentsOnly "network"
.EXAMPLE
    Deploy-Infrastructure -Force -Monitor
.NOTES
    Author: Jurie Smit (Original)
    Updated: March 9, 2025 – Adjusted to use a runspace factory and a monitoring class.
#>

#----------------------------------------------------------------------
# DeploymentMonitor class encapsulates the monitoring logic.
#----------------------------------------------------------------------
class DeploymentMonitor {
    [string]$ResourceGroup
    [string]$ResourceType
    [string]$ResourceName
    [int]$PollIntervalSeconds
    [int]$TimeoutMinutes

    DeploymentMonitor([string]$ResourceGroup, [string]$ResourceType, [string]$ResourceName, [int]$PollIntervalSeconds, [int]$TimeoutMinutes) {
        $this.ResourceGroup      = $ResourceGroup
        $this.ResourceType       = $ResourceType
        $this.ResourceName       = $ResourceName
        $this.PollIntervalSeconds = $PollIntervalSeconds
        $this.TimeoutMinutes     = $TimeoutMinutes
    }

    [bool] Monitor() {
        # Here we assume Monitor-AzureResourceDeployment is available in your environment.
        # It should return a Boolean indicating whether the deployment was successful.
        $result = Monitor-AzureResourceDeployment -ResourceGroup $this.ResourceGroup `
                                                  -ResourceType $this.ResourceType `
                                                  -ResourceName $this.ResourceName `
                                                  -PollIntervalSeconds $this.PollIntervalSeconds `
                                                  -TimeoutMinutes $this.TimeoutMinutes
        return $result
    }
}

#----------------------------------------------------------------------
# Main deployment function
#----------------------------------------------------------------------
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
        [switch]$Monitor
    )
    
    # Ensure we're connected to Azure
    if (-not (Connect-AzureAccount)) {
        Write-Log -Message "Failed to connect to Azure. Deployment aborted." -Level Error
        return $false
    }
    
    # Retrieve global configuration
    $config   = Get-Configuration
    $env      = $config.env
    $loc      = $config.loc
    $project  = $config.project
    $location = $config.location
    
    # Construct the resource group name if not provided
    if (-not $ResourceGroup) {
        $ResourceGroup = "$env-$loc-rg-$project"
    }
    
    # Check if resource group exists; create it if it doesn't
    if (-not (Test-ResourceGroup -ResourceGroupName $ResourceGroup)) {
        Write-Log -Message "Creating resource group '$ResourceGroup' in location '$location'..." -Level Info
        try {
            az group create --name $ResourceGroup --location $location | Out-Null
        }
        catch {
            Write-Log -Message "Failed to create resource group: $($_.Exception.Message)" -Level Error
            return $false
        }
    }
    
    # Get the templates path
    $templatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
    
    Write-Log -Message "Starting deployment for resource group: $ResourceGroup" -Level Info
    
    # Define common deployment parameters
    $commonParams = @(
        "--resource-group", $ResourceGroup,
        "--parameters", "location=$location", "env=$env", "loc=$loc", "project=$project"
    )
    
    if (-not $Force) {
        $commonParams += "--confirm-with-what-if"
    }
    
    if ($Monitor) {
        $commonParams += "--no-wait"
    }
    
    #------------------------------------------------------------------
    # Helper function to invoke a deployment and (optionally) monitor it
    #------------------------------------------------------------------
    function Invoke-Deployment {
        param(
            [string]$TemplateFile,
            [string]$ComponentName,
            [string]$ResourceType,
            [string]$ResourceName,
            [int]$PollIntervalSeconds = 10,
            [int]$TimeoutMinutes = 30
        )
        Write-Log -Message "Deploying $ComponentName using $TemplateFile" -Level Info
        
        $deployCmd = @("az", "deployment", "group", "create", "--template-file", $TemplateFile) + $commonParams
        Write-Log -Message "Executing: $($deployCmd -join ' ')" -Level Debug
        
        try {
            & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        }
        catch {
            Write-Log -Message "$ComponentName deployment encountered an error: $($_.Exception.Message)" -Level Error
            return $false
        }
        
        if (-not $Monitor -and ($LASTEXITCODE -ne 0)) {
            Write-Log -Message "$ComponentName deployment failed with exit code $LASTEXITCODE" -Level Error
            return $false
        }
        
        # If monitoring is enabled, use a runspace to execute the monitoring concurrently.
        if ($Monitor) {
            # Define a script block that creates an instance of DeploymentMonitor and calls its Monitor() method.
            $monitorScript = {
                param($ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes)
                $monitorInstance = [DeploymentMonitor]::new($ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes)
                return $monitorInstance.Monitor()
            }
            
            # Create a runspace pool using RunspaceFactory.
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
            $runspacePool.Open()
            $psInstance = [powershell]::Create()
            $psInstance.RunspacePool = $runspacePool
            
            # Pass in required parameters.
            $psInstance.AddScript($monitorScript).AddArgument($ResourceGroup).AddArgument($ResourceType).AddArgument($ResourceName).AddArgument($PollIntervalSeconds).AddArgument($TimeoutMinutes) | Out-Null
            
            # Begin asynchronous invocation and wait for completion.
            $handle = $psInstance.BeginInvoke()
            $resultMonitor = $psInstance.EndInvoke($handle)
            
            $psInstance.Dispose()
            $runspacePool.Close()
            $runspacePool.Dispose()
            
            if (-not $resultMonitor) {
                Write-Log -Message "$ComponentName deployment monitoring failed or timed out" -Level Warning
                return $false
            }
        }
        
        Write-Log -Message "$ComponentName deployment completed successfully" -Level Success
        return $true
    }
    
    #------------------------------------------------------------------
    # Deploy components based on the ComponentsOnly parameter
    #------------------------------------------------------------------
    if ($ComponentsOnly -eq "network") {
        $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        $resourceName = "$env-$loc-vnet-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "Network" -ResourceType "vnet" -ResourceName $resourceName -PollIntervalSeconds 10)) {
            return $false
        }
    }
    elseif ($ComponentsOnly -eq "vpngateway") {
        $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        $resourceName = "$env-$loc-vpng-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "VPN Gateway" -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60)) {
            return $false
        }
    }
    elseif ($ComponentsOnly -eq "natgateway") {
        $templateFile = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        $resourceName = "$env-$loc-natgw-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "NAT Gateway" -ResourceType "nat-gateway" -ResourceName $resourceName -PollIntervalSeconds 10)) {
            return $false
        }
    }
    else {
        Write-Log -Message "Deploying full infrastructure: Network, VPN Gateway, and NAT Gateway" -Level Info
        
        # Deploy Network
        $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        $resourceName = "$env-$loc-vnet-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "Network" -ResourceType "vnet" -ResourceName $resourceName -PollIntervalSeconds 10)) {
            return $false
        }
        
        # Deploy VPN Gateway
        $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        $resourceName = "$env-$loc-vpng-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "VPN Gateway" -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60)) {
            return $false
        }
        
        # Deploy NAT Gateway
        $templateFile = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        $resourceName = "$env-$loc-natgw-$project"
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "NAT Gateway" -ResourceType "nat-gateway" -ResourceName $resourceName -PollIntervalSeconds 10)) {
            return $false
        }
    }
    
    Write-Log -Message "Deployment completed successfully." -Level Success
    return $true
}
