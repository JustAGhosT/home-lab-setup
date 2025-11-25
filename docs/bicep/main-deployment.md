# Main Deployment Template

This document details the main Bicep template used for orchestrating the deployment of the HomeLab environment.

## Template Purpose

The main deployment template (`main.bicep`) serves as the orchestrator for the entire HomeLab environment deployment. It creates the resource group and coordinates the deployment of all child modules in the correct order with appropriate dependencies.

## Deployment Scope

This template operates at the subscription scope, allowing it to create the resource group that will contain all HomeLab resources:

```bicep
targetScope = 'subscription'
```

## Resource Components

### Resource Group

The template creates a resource group to contain all HomeLab resources:

- **Name**: `{env}-{loc}-rg-{project}` (e.g., `dev-saf-rg-homelab`)
- **Location**: South Africa North (customizable)

### Module Deployments

The template orchestrates the deployment of the following modules:

1. **Network Infrastructure**: Creates the virtual network, subnets, and security groups
   - Deployed directly within the newly created resource group

2. **VPN Gateway**: (Indirectly deployed through the network module)
   - Creates the gateway subnet and optionally deploys the VPN Gateway

3. **NAT Gateway**: (Indirectly deployed through the network module)
   - Creates the NAT Gateway and optionally associates it with subnets

## Parameters

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| location | southafricanorth | Azure region for resource deployment |
| env | dev | Environment prefix (dev, test, prod) |
| loc | saf | Location abbreviation for resource naming |
| project | homelab | Project name for resource naming |

## Outputs

The template outputs the following values:

- Resource Group Name
- Resource Group ID

## Usage Example

```powershell
# Deploy using Azure PowerShell at subscription scope
New-AzDeployment `
  -Location "southafricanorth" `
  -TemplateFile "./main.bicep" `
  -env "dev" `
  -loc "saf" `
  -project "homelab"
```

## Deployment Strategy

The main template follows a hierarchical deployment approach:

1. Create the resource group
2. Deploy the network infrastructure within that resource group
3. The network infrastructure template then deploys the VPN and NAT gateways

This approach ensures proper dependency management and allows for clean, complete deployments from a single command.

## Customization Options

- Change the location parameter to deploy in a different Azure region
- Modify the environment prefix for different deployment environments (dev, test, prod)
- Adjust the project name for different lab scenarios or projects

## Integration with PowerShell Module

This template is designed to be called from the HomeLab PowerShell module, which provides an interactive menu system for deployment and configuration. The module handles parameter collection and passes the values to this template.
