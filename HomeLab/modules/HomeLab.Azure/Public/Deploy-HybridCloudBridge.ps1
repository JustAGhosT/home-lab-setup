function Deploy-HybridCloudBridge {
    <#
    .SYNOPSIS
        Deploys hybrid cloud bridge for on-premises and cloud connectivity.
    
    .DESCRIPTION
        Deploys hybrid cloud bridge infrastructure including VPN gateways,
        ExpressRoute connections, and hybrid networking components.
    
    .PARAMETER ResourceGroup
        The resource group name for the hybrid infrastructure.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER ProjectName
        The name of the hybrid cloud project.
    
    .PARAMETER OnPremisesNetwork
        The on-premises network CIDR block.
    
    .PARAMETER EnableVPNGateway
        Whether to enable VPN Gateway for site-to-site connectivity.
    
    .PARAMETER EnableExpressRoute
        Whether to enable ExpressRoute for dedicated connectivity.
    
    .PARAMETER EnableAzureBastion
        Whether to enable Azure Bastion for secure access.
    
    .PARAMETER EnableHybridDNS
        Whether to enable hybrid DNS resolution.
    
    .PARAMETER EnableHybridMonitoring
        Whether to enable hybrid monitoring and logging.
    
    .PARAMETER EnableHybridSecurity
        Whether to enable hybrid security policies.
    
    .PARAMETER EnableHybridBackup
        Whether to enable hybrid backup solutions.
    
    .PARAMETER EnableHybridDisasterRecovery
        Whether to enable hybrid disaster recovery.
    
    .EXAMPLE
        Deploy-HybridCloudBridge -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-hybrid-project"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        
        [Parameter(Mandatory = $false)]
        [string]$OnPremisesNetwork = "192.168.0.0/16",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableVPNGateway = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableExpressRoute = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableAzureBastion = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHybridDNS = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHybridMonitoring = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHybridSecurity = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHybridBackup = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHybridDisasterRecovery = $false
    )
    
    try {
        Write-ColorOutput "Starting Hybrid Cloud Bridge deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Create hybrid project configuration
        Write-ColorOutput "Creating hybrid project configuration..." -ForegroundColor Yellow
        $projectConfig = @{
            ProjectName                  = $ProjectName
            ResourceGroup                = $ResourceGroup
            Location                     = $Location
            OnPremisesNetwork            = $OnPremisesNetwork
            EnableVPNGateway             = $EnableVPNGateway
            EnableExpressRoute           = $EnableExpressRoute
            EnableAzureBastion           = $EnableAzureBastion
            EnableHybridDNS              = $EnableHybridDNS
            EnableHybridMonitoring       = $EnableHybridMonitoring
            EnableHybridSecurity         = $EnableHybridSecurity
            EnableHybridBackup           = $EnableHybridBackup
            EnableHybridDisasterRecovery = $EnableHybridDisasterRecovery
            CreatedAt                    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Create Virtual Network for hybrid connectivity
        Write-ColorOutput "Creating Virtual Network for hybrid connectivity..." -ForegroundColor Yellow
        $vnetName = "$($ProjectName.ToLower())vnet$(Get-Random -Minimum 1000 -Maximum 9999)"
        $vnetAddressSpace = "10.0.0.0/16"
        
        az network vnet create `
            --name $vnetName `
            --resource-group $ResourceGroup `
            --location $Location `
            --address-prefix $vnetAddressSpace `
            --subnet-name "default" `
            --subnet-prefix "10.0.1.0/24"
        
        # Create Gateway Subnet for VPN/ExpressRoute
        if ($EnableVPNGateway -or $EnableExpressRoute) {
            Write-ColorOutput "Creating Gateway Subnet..." -ForegroundColor Gray
            az network vnet subnet create `
                --name "GatewaySubnet" `
                --resource-group $ResourceGroup `
                --vnet-name $vnetName `
                --address-prefix "10.0.2.0/27"
        }
        
        # Create Azure Bastion Subnet if enabled
        if ($EnableAzureBastion) {
            Write-ColorOutput "Creating Azure Bastion Subnet..." -ForegroundColor Gray
            az network vnet subnet create `
                --name "AzureBastionSubnet" `
                --resource-group $ResourceGroup `
                --vnet-name $vnetName `
                --address-prefix "10.0.3.0/27"
        }
        
        # Create VPN Gateway if enabled
        if ($EnableVPNGateway) {
            Write-ColorOutput "Creating VPN Gateway..." -ForegroundColor Yellow
            
            # Create Public IP for VPN Gateway
            $vpnGatewayIPName = "$($ProjectName.ToLower())vpngwip$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network public-ip create `
                --name $vpnGatewayIPName `
                --resource-group $ResourceGroup `
                --location $Location `
                --allocation-method Dynamic
            
            # Create VPN Gateway
            $vpnGatewayName = "$($ProjectName.ToLower())vpngw$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network vnet-gateway create `
                --name $vpnGatewayName `
                --resource-group $ResourceGroup `
                --location $Location `
                --vnet $vnetName `
                --public-ip-address $vpnGatewayIPName `
                --gateway-type Vpn `
                --vpn-type RouteBased `
                --sku VpnGw1 `
                --gateway-address-prefix "10.0.2.0/27"
            
            # Create Local Network Gateway for on-premises
            $localNetworkGatewayName = "$($ProjectName.ToLower())lng$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network local-gateway create `
                --name $localNetworkGatewayName `
                --resource-group $ResourceGroup `
                --location $Location `
                --gateway-ip-address "203.0.113.1" `
                --local-address-prefixes $OnPremisesNetwork
            
            # Create VPN Connection
            $vpnConnectionName = "$($ProjectName.ToLower())vpnconn$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network vpn-connection create `
                --name $vpnConnectionName `
                --resource-group $ResourceGroup `
                --location $Location `
                --vnet-gateway1 $vpnGatewayName `
                --local-gateway2 $localNetworkGatewayName `
                --connection-type IPsec `
                --shared-key "YourSharedKey123!"
        }
        
        # Create ExpressRoute Gateway if enabled
        if ($EnableExpressRoute) {
            Write-ColorOutput "Creating ExpressRoute Gateway..." -ForegroundColor Yellow
            
            # Create Public IP for ExpressRoute Gateway
            $erGatewayIPName = "$($ProjectName.ToLower())ergwip$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network public-ip create `
                --name $erGatewayIPName `
                --resource-group $ResourceGroup `
                --location $Location `
                --allocation-method Static `
                --sku Standard
            
            # Create ExpressRoute Gateway
            $erGatewayName = "$($ProjectName.ToLower())ergw$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network vnet-gateway create `
                --name $erGatewayName `
                --resource-group $ResourceGroup `
                --location $Location `
                --vnet $vnetName `
                --public-ip-address $erGatewayIPName `
                --gateway-type ExpressRoute `
                --sku ErGw1AZ
        }
        
        # Create Azure Bastion if enabled
        if ($EnableAzureBastion) {
            Write-ColorOutput "Creating Azure Bastion..." -ForegroundColor Yellow
            
            # Create Public IP for Azure Bastion
            $bastionIPName = "$($ProjectName.ToLower())bastionip$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network public-ip create `
                --name $bastionIPName `
                --resource-group $ResourceGroup `
                --location $Location `
                --allocation-method Static `
                --sku Standard
            
            # Create Azure Bastion
            $bastionName = "$($ProjectName.ToLower())bastion$(Get-Random -Minimum 1000 -Maximum 9999)"
            az network bastion create `
                --name $bastionName `
                --resource-group $ResourceGroup `
                --location $Location `
                --vnet-name $vnetName `
                --public-ip-address $bastionIPName
        }
        
        # Create Azure DNS Private Zone if enabled
        if ($EnableHybridDNS) {
            Write-ColorOutput "Creating Azure DNS Private Zone..." -ForegroundColor Yellow
            $dnsZoneName = "$($ProjectName.ToLower()).local"
            
            az network private-dns zone create `
                --name $dnsZoneName `
                --resource-group $ResourceGroup
            
            # Link DNS zone to Virtual Network
            az network private-dns link vnet create `
                --name "$($ProjectName.ToLower())dns-link" `
                --resource-group $ResourceGroup `
                --zone-name $dnsZoneName `
                --virtual-network $vnetName `
                --registration-enabled true
        }
        
        # Create Log Analytics workspace for hybrid monitoring
        if ($EnableHybridMonitoring) {
            Write-ColorOutput "Creating Log Analytics workspace for hybrid monitoring..." -ForegroundColor Yellow
            $workspaceName = "$($ProjectName.ToLower())workspace$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az monitor log-analytics workspace create `
                --workspace-name $workspaceName `
                --resource-group $ResourceGroup `
                --location $Location
            
            # Enable monitoring for Virtual Network
            az monitor diagnostic-settings create `
                --resource $vnetName `
                --resource-group $ResourceGroup `
                --resource-type Microsoft.Network/virtualNetworks `
                --name "vnet-diagnostics" `
                --workspace $workspaceName `
                --logs '[{"category": "VMProtectionAlerts", "enabled": true}]'
        }
        
        # Create Azure Key Vault for hybrid security
        if ($EnableHybridSecurity) {
            Write-ColorOutput "Creating Azure Key Vault for hybrid security..." -ForegroundColor Yellow
            $keyVaultName = "$($ProjectName.ToLower())kv$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az keyvault create `
                --name $keyVaultName `
                --resource-group $ResourceGroup `
                --location $Location `
                --enable-soft-delete `
                --enable-rbac-authorization
        }
        
        # Create Recovery Services Vault for hybrid backup
        if ($EnableHybridBackup) {
            Write-ColorOutput "Creating Recovery Services Vault for hybrid backup..." -ForegroundColor Yellow
            $recoveryVaultName = "$($ProjectName.ToLower())rsv$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az backup vault create `
                --name $recoveryVaultName `
                --resource-group $ResourceGroup `
                --location $Location
        }
        
        # Create Site Recovery Vault for disaster recovery
        if ($EnableHybridDisasterRecovery) {
            Write-ColorOutput "Creating Site Recovery Vault for disaster recovery..." -ForegroundColor Yellow
            $siteRecoveryVaultName = "$($ProjectName.ToLower())srv$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az site-recovery vault create `
                --name $siteRecoveryVaultName `
                --resource-group $ResourceGroup `
                --location $Location
        }
        
        # Create Network Security Group for hybrid security
        if ($EnableHybridSecurity) {
            Write-ColorOutput "Creating Network Security Group..." -ForegroundColor Yellow
            $nsgName = "$($ProjectName.ToLower())nsg$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az network nsg create `
                --name $nsgName `
                --resource-group $ResourceGroup `
                --location $Location
            
            # Add security rules
            az network nsg rule create `
                --name "AllowOnPremises" `
                --resource-group $ResourceGroup `
                --nsg-name $nsgName `
                --priority 100 `
                --source-address-prefix $OnPremisesNetwork `
                --destination-address-prefix "*" `
                --destination-port-range "*" `
                --access Allow `
                --protocol "*"
            
            az network nsg rule create `
                --name "AllowAzureBastion" `
                --resource-group $ResourceGroup `
                --nsg-name $nsgName `
                --priority 200 `
                --source-address-prefix "Internet" `
                --destination-address-prefix "*" `
                --destination-port-range "443" `
                --access Allow `
                --protocol "Tcp"
        }
        
        # Create hybrid configuration file
        $configPath = Join-Path -Path $env:TEMP -ChildPath "hybrid-config.json"
        $projectConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
        
        # Create hybrid deployment script
        $deploymentScript = @"
# Hybrid Cloud Bridge Deployment Script
# Generated for project: $ProjectName

# Azure CLI Commands for Hybrid Setup

# 1. Connect to Azure
echo "Connecting to Azure..."
az login

# 2. Set subscription (if needed)
# az account set --subscription "your-subscription-id"

# 3. Create resource group (if not exists)
echo "Creating resource group..."
az group create --name "$ResourceGroup" --location "$Location"

# 4. Deploy Virtual Network
echo "Deploying Virtual Network..."
az network vnet create `
    --name "$vnetName" `
    --resource-group "$ResourceGroup" `
    --location "$Location" `
    --address-prefix "10.0.0.0/16" `
    --subnet-name "default" `
    --subnet-prefix "10.0.1.0/24"

# 5. Create Gateway Subnet
echo "Creating Gateway Subnet..."
az network vnet subnet create `
    --name "GatewaySubnet" `
    --resource-group "$ResourceGroup" `
    --vnet-name "$vnetName" `
    --address-prefix "10.0.2.0/27"

# 6. Create Azure Bastion Subnet
echo "Creating Azure Bastion Subnet..."
az network vnet subnet create `
    --name "AzureBastionSubnet" `
    --resource-group "$ResourceGroup" `
    --vnet-name "$vnetName" `
    --address-prefix "10.0.3.0/27"

# 7. Create Public IP for VPN Gateway
echo "Creating Public IP for VPN Gateway..."
az network public-ip create `
    --name "$vpnGatewayIPName" `
    --resource-group "$ResourceGroup" `
    --location "$Location" `
    --allocation-method Dynamic

# 8. Create VPN Gateway
echo "Creating VPN Gateway..."
az network vnet-gateway create `
    --name "$vpnGatewayName" `
    --resource-group "$ResourceGroup" `
    --location "$Location" `
    --vnet "$vnetName" `
    --public-ip-address "$vpnGatewayIPName" `
    --gateway-type Vpn `
    --vpn-type RouteBased `
    --sku VpnGw1 `
    --gateway-address-prefix "10.0.2.0/27"

# 9. Create Local Network Gateway
echo "Creating Local Network Gateway..."
az network local-gateway create `
    --name "$localNetworkGatewayName" `
    --resource-group "$ResourceGroup" `
    --location "$Location" `
    --gateway-ip-address "YOUR_ONPREMISES_GATEWAY_IP" `
    --local-address-prefixes "$OnPremisesNetwork"

# 10. Create VPN Connection
echo "Creating VPN Connection..."
az network vpn-connection create `
    --name "$vpnConnectionName" `
    --resource-group "$ResourceGroup" `
    --location "$Location" `
    --vnet-gateway1 "$vpnGatewayName" `
    --local-gateway2 "$localNetworkGatewayName" `
    --connection-type IPsec `
    --shared-key "YOUR_SHARED_KEY"

echo "Hybrid Cloud Bridge deployment completed!"
echo "Project: $ProjectName"
echo "Resource Group: $ResourceGroup"
echo "Virtual Network: $vnetName"
echo "VPN Gateway: $vpnGatewayName"
"@
        
        $scriptPath = Join-Path -Path $env:TEMP -ChildPath "hybrid-deployment.ps1"
        $deploymentScript | Set-Content -Path $scriptPath
        
        # Display deployment summary
        Write-ColorOutput "`nHybrid Cloud Bridge deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Project Name: $ProjectName" -ForegroundColor Gray
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Location: $Location" -ForegroundColor Gray
        Write-ColorOutput "Virtual Network: $vnetName" -ForegroundColor Gray
        Write-ColorOutput "On-Premises Network: $OnPremisesNetwork" -ForegroundColor Gray
        
        if ($EnableVPNGateway) {
            Write-ColorOutput "VPN Gateway: $vpnGatewayName" -ForegroundColor Gray
            Write-ColorOutput "Local Network Gateway: $localNetworkGatewayName" -ForegroundColor Gray
            Write-ColorOutput "VPN Connection: $vpnConnectionName" -ForegroundColor Gray
        }
        
        if ($EnableExpressRoute) {
            Write-ColorOutput "ExpressRoute Gateway: $erGatewayName" -ForegroundColor Gray
        }
        
        if ($EnableAzureBastion) {
            Write-ColorOutput "Azure Bastion: $bastionName" -ForegroundColor Gray
        }
        
        if ($EnableHybridDNS) {
            Write-ColorOutput "DNS Private Zone: $dnsZoneName" -ForegroundColor Gray
        }
        
        if ($EnableHybridMonitoring) {
            Write-ColorOutput "Log Analytics Workspace: $workspaceName" -ForegroundColor Gray
        }
        
        if ($EnableHybridSecurity) {
            Write-ColorOutput "Key Vault: $keyVaultName" -ForegroundColor Gray
            Write-ColorOutput "Network Security Group: $nsgName" -ForegroundColor Gray
        }
        
        Write-ColorOutput "Configuration Files:" -ForegroundColor Gray
        Write-ColorOutput "  - Hybrid Config: $configPath" -ForegroundColor Gray
        Write-ColorOutput "  - Deployment Script: $scriptPath" -ForegroundColor Gray
        
        # Return deployment info
        return @{
            ProjectName           = $ProjectName
            ResourceGroup         = $ResourceGroup
            Location              = $Location
            VirtualNetwork        = $vnetName
            OnPremisesNetwork     = $OnPremisesNetwork
            VPNGateway            = if ($EnableVPNGateway) { $vpnGatewayName } else { $null }
            LocalNetworkGateway   = if ($EnableVPNGateway) { $localNetworkGatewayName } else { $null }
            VPNConnection         = if ($EnableVPNGateway) { $vpnConnectionName } else { $null }
            ExpressRouteGateway   = if ($EnableExpressRoute) { $erGatewayName } else { $null }
            AzureBastion          = if ($EnableAzureBastion) { $bastionName } else { $null }
            DNSZone               = if ($EnableHybridDNS) { $dnsZoneName } else { $null }
            LogAnalyticsWorkspace = if ($EnableHybridMonitoring) { $workspaceName } else { $null }
            KeyVault              = if ($EnableHybridSecurity) { $keyVaultName } else { $null }
            NetworkSecurityGroup  = if ($EnableHybridSecurity) { $nsgName } else { $null }
            ConfigurationFiles    = @{
                HybridConfig     = $configPath
                DeploymentScript = $scriptPath
            }
            ProjectConfig         = $projectConfig
        }
    }
    catch {
        Write-ColorOutput "Error deploying Hybrid Cloud Bridge: $_" -ForegroundColor Red
        throw
    }
} 