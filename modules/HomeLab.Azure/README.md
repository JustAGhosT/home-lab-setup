# HomeLab.Azure

## Overview

HomeLab.Azure provides functionality for deploying and managing Azure infrastructure for your home lab environment. It handles Azure resource deployment, NAT gateway management, and other Azure-specific operations as part of the [HomeLab system](../../README.md).

## Features

- **Infrastructure Deployment**: Deploy Azure resources using Bicep templates
- **NAT Gateway Management**: Enable/disable NAT Gateway to control outbound traffic
- **Network Configuration**: Set up virtual networks, subnets, and other networking components
- **Resource Management**: Create and manage Azure resources for your home lab

## Functions

### Deployment Functions

- `Deploy-Infrastructure`: Deploys the complete Azure infrastructure using Bicep templates
- `Deploy-NetworkInfrastructure`: Deploys just the networking components
- `Deploy-VpnGateway`: Deploys a VPN gateway for secure remote access

### NAT Gateway Functions

- `Enable-NatGateway`: Enables the NAT Gateway for outbound internet access
- `Disable-NatGateway`: Disables the NAT Gateway to save costs when not in use
- `Get-NatGatewayStatus`: Checks the current status of the NAT Gateway

### Helper Functions

- `Connect-AzureAccount`: Handles Azure authentication
- `Get-AzureSubscription`: Gets the current Azure subscription
- `Set-AzureSubscription`: Sets the Azure subscription to use
- `Test-AzureConnection`: Tests if there's an active Azure connection

## Installation

This module is part of the HomeLab system and is automatically loaded by the main HomeLab module. To use it independently:

```powershell
Import-Module -Name ".\HomeLab.Azure.psm1"
# Note: HomeLab.Core must be loaded first
```

## Configuration

This module relies on configuration settings from [HomeLab.Core](../HomeLab.Core/README.md), particularly:

- Azure subscription ID
- Azure location
- Resource group naming convention
- Network settings

## Example Usage

```powershell
# Connect to Azure
Connect-AzureAccount

# Deploy the complete infrastructure
Deploy-Infrastructure

# Enable NAT Gateway
Enable-NatGateway
```

## Dependencies

- [HomeLab.Core](../HomeLab.Core/README.md) module
- Az PowerShell module (9.0.0 or higher)
- PowerShell 5.1 or higher

## Related Modules

- [HomeLab.Core](../HomeLab.Core/README.md) - Provides configuration and logging
- [HomeLab.Security](../HomeLab.Security/README.md) - Uses Azure resources for VPN setup
- [HomeLab.Monitoring](../HomeLab.Monitoring/README.md) - Monitors Azure resources

## Notes

This module contains the Azure-specific functionality for the HomeLab system. It requires an active Azure subscription and appropriate permissions to create resources.

[Back to main README](../../README.md)
