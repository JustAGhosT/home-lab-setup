<#
.SYNOPSIS
    Deploys Azure infrastructure for HomeLab.
.DESCRIPTION
    Retrieves global configuration and deploys either the full infrastructure or a specific component
    (network, VPN gateway, or NAT gateway) using the corresponding Bicep templates.
    If the BackgroundMonitor switch is specified, deployment monitoring runs as background jobs and the function
    returns immediately.
.PARAMETER ComponentsOnly
    Optional. Specifies a single component to deploy ("network", "vpngateway", or "natgateway").
    If not specified, full infrastructure is deployed.
.PARAMETER ResourceGroup
    Optional. The name of the resource group to deploy to. If not provided, it will be constructed from configuration.
.PARAMETER Force
    Optional. If specified, skips confirmation prompts during deployment.
.PARAMETER Monitor
    Optional. If specified, monitors the deployment until completion.
.PARAMETER BackgroundMonitor
    Optional. If specified, starts background monitoring jobs instead of blocking the console.
.EXAMPLE
    Deploy-Infrastructure -ComponentsOnly "network"
.EXAMPLE
    Deploy-Infrastructure -Force -BackgroundMonitor
.NOTES
    Author: Jurie Smit (Original)
    Updated: March 9, 2025 – Adjusted to include new parameters and split into maintainable parts with enhanced logging.
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
    
    Write-Log -Message "==== Starting Deploy-Infrastructure ====" -Level Info

    # Ensure we're connected to Azure.
    if (-not (Connect-AzureAccount)) {
        Write-Log -Message "Failed to connect to Azure. Deployment aborted." -Level Error
        return $false
    }
    
    # Retrieve global configuration.
    $config = Get-Configuration
    $env      = $config.env
    $loc      = $config.loc
    $project  = $config.project
    $location = $config.location
    Write-Log -Message "Configuration: env=$env, loc=$loc, project=$project, location=$location" -Level Debug

    # Construct the resource group name if not provided.
    if (-not $ResourceGroup) {
        $ResourceGroup = "$env-$loc-rg-$project"
        Write-Log -Message "ResourceGroup not provided; using default: $ResourceGroup" -Level Debug
    }
    
    # Check if resource group exists; create if it doesn't.
    if (-not (Test-ResourceGroup -ResourceGroupName $ResourceGroup)) {
        Write-Log -Message "Resource group '$ResourceGroup' does not exist. Creating..." -Level Info
        try {
            az group create --name $ResourceGroup --location $location | Out-Null
            Write-Log -Message "Resource group '$ResourceGroup' created successfully." -Level Info
        }
        catch {
            Write-Log -Message "Failed to create resource group: $($_.Exception.Message)" -Level Error
            return $false
        }
    }
    else {
        Write-Log -Message "Resource group '$ResourceGroup' exists." -Level Info
    }
    
    # Get the templates path.
    $templatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
    Write-Log -Message "Templates path: $templatesPath" -Level Debug
    
    Write-Log -Message "Starting deployment for resource group: $ResourceGroup" -Level Info
    
    # Define common deployment parameters, including new flags.
    $commonParams = @(
        "--resource-group", $ResourceGroup,
        "--parameters", "location=$location", "env=$env", "loc=$loc", "project=$project",
                        "enableNatGateway=$($config.natGateway.enabled)", "enableVpnGateway=$($config.vpn.enabled)"
    )
    Write-Log -Message "Common parameters: $($commonParams -join ' ')" -Level Debug
    
    if (-not $Force) {
        $commonParams += "--confirm-with-what-if"
        Write-Log -Message "Added confirmation parameter." -Level Debug
    }
    if ($Monitor -or $BackgroundMonitor) {
        $commonParams += "--no-wait"
        Write-Log -Message "Added no-wait parameter (monitoring enabled)." -Level Debug
    }
    
    # Dispatch to the appropriate component deployment function.
    if ($ComponentsOnly -eq "network") {
        return Deploy-NetworkComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor
    }
    elseif ($ComponentsOnly -eq "vpngateway") {
        return Deploy-VPNGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor
    }
    elseif ($ComponentsOnly -eq "natgateway") {
        return Deploy-NATGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor
    }
    else {
        if (-not (Deploy-FullInfrastructure -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
            return $false
        }
        return $true
    }
}