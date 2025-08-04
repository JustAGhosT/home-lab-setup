function Configure-HybridConnectivity {
    <#
    .SYNOPSIS
        Configures hybrid connectivity and settings.
    
    .DESCRIPTION
        Configures connectivity and settings for hybrid cloud deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER ProjectName
        The hybrid cloud project name.
    
    .PARAMETER VirtualNetwork
        The virtual network name.
    
    .PARAMETER OnPremisesNetwork
        The on-premises network CIDR.
    
    .PARAMETER VPNGateway
        The VPN gateway name.
    
    .PARAMETER LocalNetworkGateway
        The local network gateway name.
    
    .PARAMETER VPNConnection
        The VPN connection name.
    
    .PARAMETER ExpressRouteGateway
        The ExpressRoute gateway name.
    
    .PARAMETER AzureBastion
        The Azure Bastion name.
    
    .PARAMETER DNSZone
        The DNS private zone name.
    
    .PARAMETER LogAnalyticsWorkspace
        The Log Analytics workspace name.
    
    .PARAMETER KeyVault
        The Key Vault name.
    
    .PARAMETER NetworkSecurityGroup
        The Network Security Group name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-HybridConnectivity -ResourceGroup "my-rg" -ProjectName "my-hybrid-project"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        
        [Parameter(Mandatory = $false)]
        [string]$VirtualNetwork,
        
        [Parameter(Mandatory = $false)]
        [string]$OnPremisesNetwork,
        
        [Parameter(Mandatory = $false)]
        [string]$VPNGateway,
        
        [Parameter(Mandatory = $false)]
        [string]$LocalNetworkGateway,
        
        [Parameter(Mandatory = $false)]
        [string]$VPNConnection,
        
        [Parameter(Mandatory = $false)]
        [string]$ExpressRouteGateway,
        
        [Parameter(Mandatory = $false)]
        [string]$AzureBastion,
        
        [Parameter(Mandatory = $false)]
        [string]$DNSZone,
        
        [Parameter(Mandatory = $false)]
        [string]$LogAnalyticsWorkspace,
        
        [Parameter(Mandatory = $false)]
        [string]$KeyVault,
        
        [Parameter(Mandatory = $false)]
        [string]$NetworkSecurityGroup,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring hybrid connectivity..." -ForegroundColor Cyan
        
        # Display hybrid configuration information
        Write-ColorOutput "`nHybrid Cloud Configuration Information:" -ForegroundColor Green
        Write-ColorOutput "Project Name: $ProjectName" -ForegroundColor Gray
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Virtual Network: $VirtualNetwork" -ForegroundColor Gray
        Write-ColorOutput "On-Premises Network: $OnPremisesNetwork" -ForegroundColor Gray
        
        if ($VPNGateway) {
            Write-ColorOutput "VPN Gateway: $VPNGateway" -ForegroundColor Gray
            Write-ColorOutput "Local Network Gateway: $LocalNetworkGateway" -ForegroundColor Gray
            Write-ColorOutput "VPN Connection: $VPNConnection" -ForegroundColor Gray
        }
        
        if ($ExpressRouteGateway) {
            Write-ColorOutput "ExpressRoute Gateway: $ExpressRouteGateway" -ForegroundColor Gray
        }
        
        if ($AzureBastion) {
            Write-ColorOutput "Azure Bastion: $AzureBastion" -ForegroundColor Gray
        }
        
        if ($DNSZone) {
            Write-ColorOutput "DNS Private Zone: $DNSZone" -ForegroundColor Gray
        }
        
        if ($LogAnalyticsWorkspace) {
            Write-ColorOutput "Log Analytics Workspace: $LogAnalyticsWorkspace" -ForegroundColor Gray
        }
        
        if ($KeyVault) {
            Write-ColorOutput "Key Vault: $KeyVault" -ForegroundColor Gray
        }
        
        if ($NetworkSecurityGroup) {
            Write-ColorOutput "Network Security Group: $NetworkSecurityGroup" -ForegroundColor Gray
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.HybridCloud) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "HybridCloud" -Value @{}
                }
                
                $appSettings.HybridCloud.ProjectName = $ProjectName
                $appSettings.HybridCloud.ResourceGroup = $ResourceGroup
                $appSettings.HybridCloud.VirtualNetwork = $VirtualNetwork
                $appSettings.HybridCloud.OnPremisesNetwork = $OnPremisesNetwork
                $appSettings.HybridCloud.VPNGateway = $VPNGateway
                $appSettings.HybridCloud.LocalNetworkGateway = $LocalNetworkGateway
                $appSettings.HybridCloud.VPNConnection = $VPNConnection
                $appSettings.HybridCloud.ExpressRouteGateway = $ExpressRouteGateway
                $appSettings.HybridCloud.AzureBastion = $AzureBastion
                $appSettings.HybridCloud.DNSZone = $DNSZone
                $appSettings.HybridCloud.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
                $appSettings.HybridCloud.KeyVault = $KeyVault
                $appSettings.HybridCloud.NetworkSecurityGroup = $NetworkSecurityGroup
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.hybridCloudProjectName = $ProjectName
                $packageJson.config.hybridCloudResourceGroup = $ResourceGroup
                $packageJson.config.hybridCloudVirtualNetwork = $VirtualNetwork
                $packageJson.config.hybridCloudOnPremisesNetwork = $OnPremisesNetwork
                $packageJson.config.hybridCloudVPNGateway = $VPNGateway
                $packageJson.config.hybridCloudLocalNetworkGateway = $LocalNetworkGateway
                $packageJson.config.hybridCloudVPNConnection = $VPNConnection
                $packageJson.config.hybridCloudExpressRouteGateway = $ExpressRouteGateway
                $packageJson.config.hybridCloudAzureBastion = $AzureBastion
                $packageJson.config.hybridCloudDNSZone = $DNSZone
                $packageJson.config.hybridCloudLogAnalyticsWorkspace = $LogAnalyticsWorkspace
                $packageJson.config.hybridCloudKeyVault = $KeyVault
                $packageJson.config.hybridCloudNetworkSecurityGroup = $NetworkSecurityGroup
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# Hybrid Cloud Configuration
HYBRID_CLOUD_PROJECT_NAME=$ProjectName
HYBRID_CLOUD_RESOURCE_GROUP=$ResourceGroup
HYBRID_CLOUD_VIRTUAL_NETWORK=$VirtualNetwork
HYBRID_CLOUD_ONPREMISES_NETWORK=$OnPremisesNetwork
HYBRID_CLOUD_VPN_GATEWAY=$VPNGateway
HYBRID_CLOUD_LOCAL_NETWORK_GATEWAY=$LocalNetworkGateway
HYBRID_CLOUD_VPN_CONNECTION=$VPNConnection
HYBRID_CLOUD_EXPRESS_ROUTE_GATEWAY=$ExpressRouteGateway
HYBRID_CLOUD_AZURE_BASTION=$AzureBastion
HYBRID_CLOUD_DNS_ZONE=$DNSZone
HYBRID_CLOUD_LOG_ANALYTICS_WORKSPACE=$LogAnalyticsWorkspace
HYBRID_CLOUD_KEY_VAULT=$KeyVault
HYBRID_CLOUD_NETWORK_SECURITY_GROUP=$NetworkSecurityGroup
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\hybrid-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ProjectName           = $ProjectName
            ResourceGroup         = $ResourceGroup
            VirtualNetwork        = $VirtualNetwork
            OnPremisesNetwork     = $OnPremisesNetwork
            VPNGateway            = $VPNGateway
            LocalNetworkGateway   = $LocalNetworkGateway
            VPNConnection         = $VPNConnection
            ExpressRouteGateway   = $ExpressRouteGateway
            AzureBastion          = $AzureBastion
            DNSZone               = $DNSZone
            LogAnalyticsWorkspace = $LogAnalyticsWorkspace
            KeyVault              = $KeyVault
            NetworkSecurityGroup  = $NetworkSecurityGroup
            CreatedAt             = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath
        Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        
        Write-ColorOutput "`nHybrid connectivity configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring hybrid connectivity: $_" -ForegroundColor Red
        throw
    }
} 