# VPN Gateway Template

This document details the Bicep template used for deploying the VPN Gateway component of the HomeLab environment.

## Template Purpose

The VPN Gateway template (`vpn-gateway.bicep`) creates a secure Point-to-Site (P2S) VPN connection to the HomeLab environment, enabling remote access from client devices. The template is designed with cost optimization in mind, allowing for conditional deployment of the gateway.

## Resource Components

### Gateway Subnet

The template creates a dedicated subnet for the VPN Gateway:

- **Name**: GatewaySubnet (required name for Azure VPN Gateway)
- **Default Address Range**: 10.0.255.0/27 (minimum size required)
- **Note**: This subnet is always created as it doesn't incur costs until a gateway is deployed

### Public IP Address

A public IP is deployed for the VPN Gateway (only if gateway deployment is enabled):

- **Name**: `{env}-{loc}-pip-vpng-{project}` (e.g., `dev-saf-pip-vpng-homelab`)
- **Allocation Method**: Dynamic (suitable for Basic SKU)
- **Note**: This resource incurs a small cost even when the gateway is not actively used

### VPN Gateway

The VPN Gateway itself is conditionally deployed based on the `enableVpnGateway` parameter:

- **Name**: `{env}-{loc}-vpng-{project}` (e.g., `dev-saf-vpng-homelab`)
- **Default SKU**: Basic (lowest cost option, ~$27/month)
- **Gateway Type**: Vpn (standard VPN gateway)
- **VPN Type**: RouteBased (supports multiple connection types)
- **Client Address Pool**: 172.16.0.0/24 (for client connections)
- **Split Tunneling**: Enabled by default (only routes VNet traffic through VPN)

## Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| location | southafricanorth | Azure region for resource deployment |
| env | dev | Environment prefix (dev, test, prod) |
| loc | saf | Location abbreviation for resource naming |
| project | homelab | Project name for resource naming |
| existingVnetName | (required) | Name of the existing virtual network |
| gatewaySubnetName | GatewaySubnet | Name for the gateway subnet |
| gatewaySubnetPrefix | 10.0.255.0/27 | Address prefix for the gateway subnet |
| gatewaySku | Basic | SKU for the VPN Gateway (Basic, VpnGw1, VpnGw2, VpnGw3) |
| gatewayType | Vpn | Type of gateway (Vpn or ExpressRoute) |
| vpnType | RouteBased | VPN type (RouteBased or PolicyBased) |
| enableVpnGateway | false | Whether to deploy the actual VPN Gateway |
| vpnClientAddressPoolPrefix | 172.16.0.0/24 | Address space for VPN clients |
| enableSplitTunneling | true | Enable split tunneling for VPN clients |

## Cost Optimization

The template is designed with cost optimization in mind:

1. The `enableVpnGateway` parameter defaults to `false`, allowing the subnet to be created without deploying the costly gateway
2. The Basic SKU is used by default to minimize costs (~$27/month vs. $127+/month for higher SKUs)
3. Split tunneling is enabled by default to reduce bandwidth usage

## Outputs

The template outputs the following values (empty strings if gateway is not deployed):

- VPN Gateway Resource ID
- VPN Gateway Public IP Resource ID

## Usage Example

```powershell
# Deploy using Azure PowerShell (prepare subnet only)
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./vpn-gateway.bicep" `
  -existingVnetName "dev-saf-vnet-homelab" `
  -enableVpnGateway $false

# Deploy with VPN Gateway enabled
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./vpn-gateway.bicep" `
  -existingVnetName "dev-saf-vnet-homelab" `
  -enableVpnGateway $true `
  -gatewaySku "Basic" `
  -vpnClientAddressPoolPrefix "172.16.0.0/24"
```

## Post-Deployment Configuration

After deploying the VPN Gateway, additional configuration is required:

1. Generate and upload root certificates for authentication
2. Create client certificates for each connecting device
3. Download and configure the VPN client on each device

These steps are handled by the HomeLab PowerShell module. For details, see the [VPN Gateway Guide](../networking/vpn-gateway.md) and [Certificate Management Guide](../security/client-certificate-management.md).

## Limitations

- Basic SKU does not support Azure Active Directory authentication
- Basic SKU is limited to 10 P2S connections (sufficient for most home labs)
- Deployment time is approximately 30-45 minutes
- Changes to the gateway configuration may require redeployment
