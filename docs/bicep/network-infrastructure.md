# Network Infrastructure Template

This document details the Bicep template used for deploying the network infrastructure components of the HomeLab environment.

## Template Purpose

The network infrastructure template (`network.bicep`) creates the foundation for the HomeLab environment, including:

- Virtual Network with address space
- Multiple subnets for different workloads
- Network Security Groups with preconfigured rules
- Integration points for NAT Gateway and VPN Gateway

## Resource Components

### Virtual Network

The template deploys a virtual network with the following default configuration:

- **Name**: `{env}-{loc}-vnet-{project}` (e.g., `dev-saf-vnet-homelab`)
- **Address Space**: 10.0.0.0/16 (customizable via parameters)
- **Location**: South Africa North (customizable)

### Subnets

Three primary subnets are created:

1. **Default Subnet**
   - Purpose: General purpose VMs and resources
   - Default Address Range: 10.0.0.0/24
   - Associated NSG: Default NSG with SSH and RDP access

2. **Application Subnet**
   - Purpose: Application workloads and services
   - Default Address Range: 10.0.1.0/24
   - Associated NSG: App NSG with HTTP and HTTPS access

3. **Database Subnet**
   - Purpose: Database servers and storage
   - Default Address Range: 10.0.2.0/24
   - Associated NSG: DB NSG with SQL and MySQL access from app subnet

### Network Security Groups

Three NSGs are deployed with predefined security rules:

1. **Default NSG**
   - Allows SSH (port 22) and RDP (port 3389) from any source
   - Named: `{env}-{loc}-nsg-default-{project}`

2. **Application NSG**
   - Allows HTTP (port 80) and HTTPS (port 443) from any source
   - Named: `{env}-{loc}-nsg-app-{project}`

3. **Database NSG**
   - Allows SQL Server (port 1433) and MySQL (port 3306) from application subnet only
   - Named: `{env}-{loc}-nsg-db-{project}`

## Subnet Integration

The network template also calls child modules to integrate with:

- **NAT Gateway**: For outbound internet connectivity (disabled by default)
- **VPN Gateway**: For secure remote access (subnet created but gateway not deployed by default)

## Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| location | southafricanorth | Azure region for resource deployment |
| env | dev | Environment prefix (dev, test, prod) |
| loc | saf | Location abbreviation for resource naming |
| project | homelab | Project name for resource naming |
| vnetAddressPrefix | 10.0.0.0/16 | Address space for the virtual network |
| defaultSubnetPrefix | 10.0.0.0/24 | Address prefix for the default subnet |
| appSubnetPrefix | 10.0.1.0/24 | Address prefix for the application subnet |
| dbSubnetPrefix | 10.0.2.0/24 | Address prefix for the database subnet |

## Outputs

The template outputs the following values for reference by other templates:

- Virtual Network Name and Resource ID
- Subnet Names and Resource IDs for all three subnets

## Usage Example

```powershell
# Deploy using Azure PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./network.bicep" `
  -env "dev" `
  -loc "saf" `
  -project "homelab" `
  -vnetAddressPrefix "192.168.0.0/16"
```

## Customization Options

- Modify subnet address ranges to accommodate different network designs
- Add additional subnets by extending the template
- Customize NSG rules for specific security requirements
- Change the region to deploy in different Azure locations

## Security Considerations

- NSG rules are configured with broad access for lab purposes
- For production use, restrict source address prefixes to specific IPs or ranges
- Consider adding Azure Firewall for additional security in sensitive environments
