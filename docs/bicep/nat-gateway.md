# NAT Gateway Template

This document details the Bicep template used for deploying the NAT Gateway component of the HomeLab environment.

## Template Purpose

The NAT Gateway template (`nat-gateway.bicep`) creates a Network Address Translation (NAT) Gateway to provide outbound internet connectivity for resources in the HomeLab environment. The template is designed with cost optimization in mind, allowing for conditional association with subnets.

## Resource Components

### Public IP Address

A static public IP is deployed for the NAT Gateway:

- **Name**: `{env}-{loc}-pip-ng-{project}` (e.g., `dev-saf-pip-ng-homelab`)
- **Allocation Method**: Static (required for NAT Gateway)
- **SKU**: Standard (required for NAT Gateway)
- **Note**: This resource incurs a small cost (~$3-5/month) even when the gateway is not actively used

### NAT Gateway

The NAT Gateway itself is always deployed, but subnet associations are conditional:

- **Name**: `{env}-{loc}-ng-{project}` (e.g., `dev-saf-ng-homelab`)
- **SKU**: Standard (only available option)
- **Idle Timeout**: 4 minutes (configurable)
- **Cost**: ~$32/month plus data processing charges

### Subnet Associations

The template can conditionally associate the NAT Gateway with specified subnets:

- Uses a dynamic loop to process multiple subnets
- Only associates if `enableNatGateway` parameter is `true`
- Preserves existing subnet configurations

## Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| location | southafricanorth | Azure region for resource deployment |
| env | dev | Environment prefix (dev, test, prod) |
| loc | saf | Location abbreviation for resource naming |
| project | homelab | Project name for resource naming |
| existingVnetName | (required) | Name of the existing virtual network |
| subnetNames | (required) | Array of subnet names to associate with NAT Gateway |
| enableNatGateway | false | Whether to associate the NAT Gateway with subnets |

## Cost Optimization

The template is designed with cost optimization in mind:

1. The `enableNatGateway` parameter defaults to `false`, allowing the gateway to be deployed without associating it with subnets
2. This approach enables quick enabling/disabling of the NAT Gateway without redeployment
3. When not associated with subnets, the NAT Gateway incurs minimal costs (only the public IP charge)

## Outputs

The template outputs the following values:

- NAT Gateway Resource ID
- NAT Gateway Public IP Resource ID

## Usage Example

```powershell
# Deploy NAT Gateway without subnet associations
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./nat-gateway.bicep" `
  -existingVnetName "dev-saf-vnet-homelab" `
  -subnetNames @("dev-saf-snet-default-homelab", "dev-saf-snet-app-homelab") `
  -enableNatGateway $false

# Enable NAT Gateway by associating with subnets
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./nat-gateway.bicep" `
  -existingVnetName "dev-saf-vnet-homelab" `
  -subnetNames @("dev-saf-snet-default-homelab", "dev-saf-snet-app-homelab") `
  -enableNatGateway $true
```

## Implementation Notes

The template uses a helper module (`get-subnet-info.bicep`) to retrieve existing subnet configurations before updating them with NAT Gateway associations. This approach preserves all existing subnet properties.

## Use Cases

The NAT Gateway provides several benefits for the HomeLab environment:

1. **Consistent Outbound IP**: All resources share a single public IP for outbound connections
2. **No Public IP per VM**: Reduces costs and security exposure by eliminating public IPs on individual VMs
3. **Higher Port Limits**: Overcomes SNAT port exhaustion issues that can occur with basic outbound rules
4. **Simplified Security**: Easier to manage outbound traffic through a single point

## Limitations

- NAT Gateway only handles outbound traffic (not inbound)
- Cannot be used simultaneously with Virtual Network Gateway on the same subnet
- Standard SKU is the only available option
- Data processing charges apply based on usage
