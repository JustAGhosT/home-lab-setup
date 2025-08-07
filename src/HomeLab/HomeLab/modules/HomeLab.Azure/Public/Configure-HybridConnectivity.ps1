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
        [ValidateScript({
                if ([string]::IsNullOrEmpty($_)) { return $true }
                
                try {
                    # Validate CIDR format using regex for basic structure
                    $cidrPattern = '^(\d{1,3}\.){3}\d{1,3}/\d{1,2}$'
                    if ($_ -notmatch $cidrPattern) {
                        throw "Invalid CIDR format. Expected format: x.x.x.x/y (e.g., 192.168.1.0/24)"
                    }
                    
                    # Parse CIDR components
                    $parts = $_.Split('/')
                    $ipString = $parts[0]
                    $subnetBits = [int]$parts[1]
                    
                    # Validate subnet mask range
                    if ($subnetBits -lt 0 -or $subnetBits -gt 32) {
                        throw "Invalid subnet mask. Must be between 0 and 32."
                    }
                    
                    # Use .NET IPAddress to validate IP format and parse
                    $ipAddress = [System.Net.IPAddress]::Parse($ipString)
                    
                    # Convert IP to bytes for network address validation
                    $ipBytes = $ipAddress.GetAddressBytes()
                    
                    # Calculate subnet mask using bit shifting
                    $subnetMaskValue = [uint32]::MaxValue -shl (32 - $subnetBits)
                    $subnetMaskBytes = [System.BitConverter]::GetBytes($subnetMaskValue)
                    if ([System.BitConverter]::IsLittleEndian) {
                        [array]::Reverse($subnetMaskBytes)
                    }
                    
                    # Calculate network address by ANDing IP with subnet mask
                    $networkBytes = @()
                    for ($i = 0; $i -lt 4; $i++) {
                        $networkBytes += $ipBytes[$i] -band $subnetMaskBytes[$i]
                    }
                    
                    # Create network address from calculated bytes
                    $networkAddress = [System.Net.IPAddress]::new($networkBytes)
                    
                    # Verify that the provided IP matches the calculated network address
                    if ($ipAddress.IPAddressToString -ne $networkAddress.IPAddressToString) {
                        throw "Invalid network address. The IP address '$ipString' is not properly aligned with the /$subnetBits subnet mask. Expected network address: $($networkAddress.IPAddressToString)/$subnetBits"
                    }
                    
                    return $true
                }
                catch [System.FormatException] {
                    throw "Invalid IP address format in CIDR notation: $_"
                }
                catch [System.OverflowException] {
                    throw "IP address value out of valid range in CIDR notation: $_"
                }
                catch {
                    # Re-throw our custom exceptions
                    throw
                }
            })]
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
                try {
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
                    Write-ColorOutput "⚠️  Note: appsettings.json contains hybrid connectivity configuration - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating appsettings.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update appsettings.json: $($_.Exception.Message)"
                }
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                try {
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
                    Write-ColorOutput "⚠️  Note: package.json contains hybrid connectivity configuration - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            if (Test-Path -Path $envPath) {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupPath = Join-Path -Path $ProjectPath -ChildPath ".env.backup.$timestamp"
                Copy-Item -Path $envPath -Destination $backupPath
                Write-ColorOutput "Backed up existing .env file to: $backupPath" -ForegroundColor Yellow
            }
            
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
            
            # Security warning for .env file
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The .env file contains hybrid connectivity configuration data." -ForegroundColor Yellow
            Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
            Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
            Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
            Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
            Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
            Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\hybrid-connections.json"
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
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains hybrid connectivity data - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nHybrid connectivity configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring hybrid connectivity: $_" -ForegroundColor Red
        throw
    }
} 