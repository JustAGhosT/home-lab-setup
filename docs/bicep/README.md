# Bicep Template Documentation

This documentation provides details on the Bicep templates used for deploying the Azure HomeLab environment. These templates follow Infrastructure as Code (IaC) principles to ensure consistent, repeatable deployments and easy management of the cloud resources.

## Template Overview

The HomeLab environment uses the following Bicep templates:

1. **Network Infrastructure Template** - Creates the virtual network, subnets, and security groups
2. **VPN Gateway Template** - Configures the Point-to-Site VPN for secure remote access
3. **NAT Gateway Template** - Sets up outbound internet connectivity for lab resources
4. **Main Deployment Template** - Orchestrates the deployment of all components
5. **Resource Monitoring Template** - Configures Azure Monitor and diagnostics settings

Each template is designed to be modular and can be deployed independently or as part of the complete HomeLab solution.

## Deployment Strategy

The templates use a hierarchical deployment approach:

```
Main Deployment Template
├── Resource Group
├── Network Infrastructure Template
│   ├── Virtual Network
│   ├── Subnets
│   └── Network Security Groups
├── VPN Gateway Template
│   ├── Gateway Subnet
│   ├── Public IP
│   └── VPN Gateway
└── NAT Gateway Template
    ├── Public IP
    └── NAT Gateway
```

This structure allows for flexible deployments where components can be enabled or disabled based on requirements and cost considerations.

## Parameter Management

Parameters are managed consistently across templates with standard naming conventions:

- **location** - Azure region for resource deployment
- **env** - Environment prefix (dev, test, prod)
- **loc** - Location abbreviation for resource naming
- **project** - Project name for resource naming

These parameters are used to generate consistent resource names following Azure naming best practices.

## Getting Started

To deploy these templates:

1. Clone the repository
2. Modify parameters as needed
3. Deploy using Azure CLI, PowerShell, or Azure DevOps pipelines

For detailed deployment instructions, see the [Setup Guide](../SETUP.md).
