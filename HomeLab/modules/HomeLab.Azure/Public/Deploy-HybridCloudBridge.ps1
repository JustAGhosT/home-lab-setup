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
    
    .PARAMETER OnPremisesGatewayIP
        The IP address of the on-premises VPN gateway. If not provided, a default test IP will be used.
    
    .PARAMETER VPNSharedKey
        The shared key for VPN connection. If not provided, a secure key will be generated automatically.
    
    .EXAMPLE
        Deploy-HybridCloudBridge -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-hybrid-project"
    
    .EXAMPLE
        Deploy-HybridCloudBridge -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-hybrid-project" -OnPremisesGatewayIP "192.168.1.1"
    
    .EXAMPLE
        $secureKey = ConvertTo-SecureString "MySecureKey123!" -AsPlainText -Force
        Deploy-HybridCloudBridge -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-hybrid-project" -VPNSharedKey $secureKey
    
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
        [bool]$EnableHybridDisasterRecovery = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$OnPremisesGatewayIP,
        
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$VPNSharedKey
    )
    
    try {
        Write-ColorOutput "Starting Hybrid Cloud Bridge deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        try {
            $rgExists = az group exists --name $ResourceGroup --output tsv
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Error checking resource group existence: Exit code $LASTEXITCODE" -ForegroundColor Red
                throw "Failed to check if resource group '$ResourceGroup' exists"
            }
            
            if ($rgExists -ne "true") {
                Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
                az group create --name $ResourceGroup --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create resource group '$ResourceGroup'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created resource group: $ResourceGroup" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Resource group already exists: $ResourceGroup" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with resource group operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle resource group '$ResourceGroup': $($_.Exception.Message)"
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
        
        try {
            az network vnet create `
                --name $vnetName `
                --resource-group $ResourceGroup `
                --location $Location `
                --address-prefix $vnetAddressSpace `
                --subnet-name "default" `
                --subnet-prefix "10.0.1.0/24"
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create Virtual Network '$vnetName'. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully created Virtual Network: $vnetName" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error creating Virtual Network: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to create Virtual Network '$vnetName': $($_.Exception.Message)"
        }
        
        # Create Gateway Subnet for VPN/ExpressRoute
        if ($EnableVPNGateway -or $EnableExpressRoute) {
            Write-ColorOutput "Creating Gateway Subnet..." -ForegroundColor Gray
            try {
                az network vnet subnet create `
                    --name "GatewaySubnet" `
                    --resource-group $ResourceGroup `
                    --vnet-name $vnetName `
                    --address-prefix "10.0.2.0/27"
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Gateway Subnet. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Gateway Subnet" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Gateway Subnet: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Gateway Subnet: $($_.Exception.Message)"
            }
        }
        
        # Create Azure Bastion Subnet if enabled
        if ($EnableAzureBastion) {
            Write-ColorOutput "Creating Azure Bastion Subnet..." -ForegroundColor Gray
            try {
                az network vnet subnet create `
                    --name "AzureBastionSubnet" `
                    --resource-group $ResourceGroup `
                    --vnet-name $vnetName `
                    --address-prefix "10.0.3.0/27"
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Azure Bastion Subnet. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Azure Bastion Subnet" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Azure Bastion Subnet: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Azure Bastion Subnet: $($_.Exception.Message)"
            }
        }
        
        # Create VPN Gateway if enabled
        if ($EnableVPNGateway) {
            Write-ColorOutput "Creating VPN Gateway..." -ForegroundColor Yellow
            
            # Handle VPN shared key
            if (-not $VPNSharedKey) {
                Write-ColorOutput "Generating secure VPN shared key..." -ForegroundColor Yellow
                $plainSharedKey = [System.Web.Security.Membership]::GeneratePassword(32, 8)
                Write-ColorOutput "Generated VPN shared key (will be displayed once for configuration)" -ForegroundColor Green
            }
            else {
                # Convert SecureString to plain text for Azure CLI
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($VPNSharedKey)
                $plainSharedKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                # Free the allocated BSTR memory to prevent memory leaks
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                Write-ColorOutput "Using provided VPN shared key" -ForegroundColor Green
            }
            
            # Handle on-premises gateway IP
            if (-not $OnPremisesGatewayIP) {
                Write-ColorOutput "Error: On-premises gateway IP address is required for VPN deployment." -ForegroundColor Red
                Write-ColorOutput "Please provide the OnPremisesGatewayIP parameter with your actual gateway IP address." -ForegroundColor Yellow
                throw "OnPremisesGatewayIP parameter is required for VPN Gateway deployment"
            }
            else {
                $gatewayIP = $OnPremisesGatewayIP
                Write-ColorOutput "Using provided on-premises gateway IP: $gatewayIP" -ForegroundColor Green
            }
            
            # Create Public IP for VPN Gateway
            $vpnGatewayIPName = "$($ProjectName.ToLower())vpngwip$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network public-ip create `
                    --name $vpnGatewayIPName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --allocation-method Dynamic
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Public IP for VPN Gateway '$vpnGatewayIPName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Public IP for VPN Gateway: $vpnGatewayIPName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Public IP for VPN Gateway: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Public IP for VPN Gateway '$vpnGatewayIPName': $($_.Exception.Message)"
            }
            
            # Create VPN Gateway
            $vpnGatewayName = "$($ProjectName.ToLower())vpngw$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
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
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create VPN Gateway '$vpnGatewayName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created VPN Gateway: $vpnGatewayName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating VPN Gateway: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create VPN Gateway '$vpnGatewayName': $($_.Exception.Message)"
            }
            
            # Create Local Network Gateway for on-premises
            $localNetworkGatewayName = "$($ProjectName.ToLower())lng$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network local-gateway create `
                    --name $localNetworkGatewayName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --gateway-ip-address $gatewayIP `
                    --local-address-prefixes $OnPremisesNetwork
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Local Network Gateway '$localNetworkGatewayName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Local Network Gateway: $localNetworkGatewayName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Local Network Gateway: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Local Network Gateway '$localNetworkGatewayName': $($_.Exception.Message)"
            }
            
            # Create VPN Connection
            $vpnConnectionName = "$($ProjectName.ToLower())vpnconn$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network vpn-connection create `
                    --name $vpnConnectionName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --vnet-gateway1 $vpnGatewayName `
                    --local-gateway2 $localNetworkGatewayName `
                    --connection-type IPsec `
                    --shared-key $plainSharedKey
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create VPN Connection '$vpnConnectionName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created VPN Connection: $vpnConnectionName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating VPN Connection: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create VPN Connection '$vpnConnectionName': $($_.Exception.Message)"
            }
            
            # Display VPN configuration details
            Write-ColorOutput "VPN Configuration Details:" -ForegroundColor Cyan
            Write-ColorOutput "  Gateway IP Address: $gatewayIP" -ForegroundColor Gray
            Write-ColorOutput "  Shared Key: $plainSharedKey" -ForegroundColor Gray
            Write-ColorOutput "  Local Network Gateway: $localNetworkGatewayName" -ForegroundColor Gray
            Write-ColorOutput "  VPN Connection: $vpnConnectionName" -ForegroundColor Gray
            
            # Security warning for VPN shared key
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The VPN shared key has been generated and displayed above." -ForegroundColor Yellow
            Write-ColorOutput "Please ensure this key is:" -ForegroundColor Yellow
            Write-ColorOutput "  • Configured on your on-premises VPN device" -ForegroundColor Yellow
            Write-ColorOutput "  • Stored securely and not committed to version control" -ForegroundColor Yellow
            Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        }
        
        # Create ExpressRoute Gateway if enabled
        if ($EnableExpressRoute) {
            Write-ColorOutput "Creating ExpressRoute Gateway..." -ForegroundColor Yellow
            
            # Create Public IP for ExpressRoute Gateway
            $erGatewayIPName = "$($ProjectName.ToLower())ergwip$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network public-ip create `
                    --name $erGatewayIPName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --allocation-method Static `
                    --sku Standard
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Public IP for ExpressRoute Gateway '$erGatewayIPName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Public IP for ExpressRoute Gateway: $erGatewayIPName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Public IP for ExpressRoute Gateway: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Public IP for ExpressRoute Gateway '$erGatewayIPName': $($_.Exception.Message)"
            }
            
            # Create ExpressRoute Gateway
            $erGatewayName = "$($ProjectName.ToLower())ergw$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network vnet-gateway create `
                    --name $erGatewayName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --vnet $vnetName `
                    --public-ip-address $erGatewayIPName `
                    --gateway-type ExpressRoute `
                    --sku ErGw1AZ
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create ExpressRoute Gateway '$erGatewayName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created ExpressRoute Gateway: $erGatewayName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating ExpressRoute Gateway: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create ExpressRoute Gateway '$erGatewayName': $($_.Exception.Message)"
            }
        }
        
        # Create Azure Bastion if enabled
        if ($EnableAzureBastion) {
            Write-ColorOutput "Creating Azure Bastion..." -ForegroundColor Yellow
            
            # Create Public IP for Azure Bastion
            $bastionIPName = "$($ProjectName.ToLower())bastionip$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network public-ip create `
                    --name $bastionIPName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --allocation-method Static `
                    --sku Standard
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Public IP for Azure Bastion '$bastionIPName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Public IP for Azure Bastion: $bastionIPName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Public IP for Azure Bastion: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Public IP for Azure Bastion '$bastionIPName': $($_.Exception.Message)"
            }
            
            # Create Azure Bastion
            $bastionName = "$($ProjectName.ToLower())bastion$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                az network bastion create `
                    --name $bastionName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --vnet-name $vnetName `
                    --public-ip-address $bastionIPName
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Azure Bastion '$bastionName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Azure Bastion: $bastionName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Azure Bastion: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Azure Bastion '$bastionName': $($_.Exception.Message)"
            }
        }
        
        # Create Azure DNS Private Zone if enabled
        if ($EnableHybridDNS) {
            Write-ColorOutput "Creating Azure DNS Private Zone..." -ForegroundColor Yellow
            $dnsZoneName = "$($ProjectName.ToLower()).local"
            
            try {
                az network private-dns zone create `
                    --name $dnsZoneName `
                    --resource-group $ResourceGroup
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create DNS Private Zone '$dnsZoneName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created DNS Private Zone: $dnsZoneName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating DNS Private Zone: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create DNS Private Zone '$dnsZoneName': $($_.Exception.Message)"
            }
            
            # Link DNS zone to Virtual Network
            try {
                az network private-dns link vnet create `
                    --name "$($ProjectName.ToLower())dns-link" `
                    --resource-group $ResourceGroup `
                    --zone-name $dnsZoneName `
                    --virtual-network $vnetName `
                    --registration-enabled true
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to link DNS zone to Virtual Network. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully linked DNS zone to Virtual Network" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error linking DNS zone to Virtual Network: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to link DNS zone to Virtual Network: $($_.Exception.Message)"
            }
        }
        
        # Create Log Analytics workspace for hybrid monitoring
        if ($EnableHybridMonitoring) {
            Write-ColorOutput "Creating Log Analytics workspace for hybrid monitoring..." -ForegroundColor Yellow
            $workspaceName = "$($ProjectName.ToLower())workspace$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            try {
                az monitor log-analytics workspace create `
                    --workspace-name $workspaceName `
                    --resource-group $ResourceGroup `
                    --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Log Analytics workspace '$workspaceName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Log Analytics workspace: $workspaceName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Log Analytics workspace: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Log Analytics workspace '$workspaceName': $($_.Exception.Message)"
            }
            
            # Enable monitoring for Virtual Network
            try {
                az monitor diagnostic-settings create `
                    --resource $vnetName `
                    --resource-group $ResourceGroup `
                    --resource-type Microsoft.Network/virtualNetworks `
                    --name "vnet-diagnostics" `
                    --workspace $workspaceName `
                    --logs '[{"category": "VMProtectionAlerts", "enabled": true}]'
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create diagnostic settings for Virtual Network. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created diagnostic settings for Virtual Network" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating diagnostic settings for Virtual Network: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create diagnostic settings for Virtual Network: $($_.Exception.Message)"
            }
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
        
        # Create Recovery Services Vault for disaster recovery
        if ($EnableHybridDisasterRecovery) {
            Write-ColorOutput "Creating Recovery Services Vault for disaster recovery..." -ForegroundColor Yellow
            $siteRecoveryVaultName = "$($ProjectName.ToLower())srv$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            try {
                az recoveryservices vault create `
                    --name $siteRecoveryVaultName `
                    --resource-group $ResourceGroup `
                    --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Recovery Services Vault '$siteRecoveryVaultName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Recovery Services Vault: $siteRecoveryVaultName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Recovery Services Vault: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Recovery Services Vault '$siteRecoveryVaultName': $($_.Exception.Message)"
            }
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

# Configuration Variables
`$ResourceGroup = "$ResourceGroup"
`$Location = "$Location"
`$ProjectName = "$ProjectName"
`$OnPremisesNetwork = "$OnPremisesNetwork"
`$gatewayIP = "$gatewayIP"
`$plainSharedKey = "$plainSharedKey"

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
    --gateway-ip-address "$gatewayIP" `
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
    --shared-key "$plainSharedKey"

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
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains hybrid cloud bridge configuration details." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
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