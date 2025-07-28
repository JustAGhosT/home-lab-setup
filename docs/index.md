---
layout: default
title: Home Lab Setup
---

This repository contains scripts and documentation for setting up and managing an Azure virtual network with VPN connectivity for a home lab environment.

## Overview

This HomeLab environment is designed to provide a comprehensive learning and testing platform for Azure services, with a focus on networking and secure remote connectivity. The setup includes:

- Azure Virtual Network with multiple subnets
- Azure VPN Gateway for secure remote access
- Azure NAT Gateway for outbound internet connectivity
- PowerShell module for managing the entire environment
- Certificate management for secure authentication
- Modular deployment scripts for easy customization

## Architecture

The HomeLab system uses a modular architecture with the following components:

- **[HomeLab.Core](./modules/HomeLab.Core/README.md)**: Foundation module with configuration, logging, and setup utilities
- **[HomeLab.Azure](./modules/HomeLab.Azure/README.md)**: Azure-specific functionality for resource deployment and management
- **[HomeLab.Security](./modules/HomeLab.Security/README.md)**: Security-related functionality including VPN and certificates
- **[HomeLab.UI](./modules/HomeLab.UI/README.md)**: User interface components including menus and handlers
- **[HomeLab.Monitoring](./modules/HomeLab.Monitoring/README.md)**: Monitoring and alerting capabilities

For a visual overview of the system architecture, see the [High-Level Architecture Diagram](docs/diagrams/high-level-architecture.md).

## Prerequisites

Before deploying the HomeLab environment, ensure you have all the necessary tools and permissions. See the [Prerequisites Guide](docs/PREREQUISITES.MD) for detailed requirements.

Key requirements include:
- Active Azure subscription with sufficient permissions
- PowerShell 7.2 or higher
- Az PowerShell Module installed (`Install-Module -Name Az -AllowClobber -Force`)
- Azure CLI installed and configured
- Administrator access on your local machine

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/JustAGhosT/azure-homelab-vpn.git
cd azure-homelab-vpn
```

### 2. Run the HomeLab Setup Script

```powershell
# Import the module
Import-Module .\HomeLab.psd1

# Start the HomeLab setup
Start-HomeLab
```

This will launch the interactive menu system where you can:
- Deploy all required Azure infrastructure
- Manage VPN certificates
- Configure VPN gateways and clients
- Enable/disable NAT Gateway
- Access documentation

### Deployment Process

Follow the [Setup Guide](docs/SETUP.md) for step-by-step instructions on deploying the HomeLab environment.

The deployment process includes:
1. Setting up the network infrastructure
2. Creating and configuring the VPN gateway
3. Managing certificates for secure authentication
4. Configuring client VPN access

## Documentation

This repository includes comprehensive documentation to help you deploy, manage, and understand your HomeLab environment:

- [Prerequisites Guide](docs/PREREQUISITES.MD) - Requirements before starting
- [Setup Guide](docs/SETUP.md) - Step-by-step deployment instructions
- [VPN Gateway Guide](docs/VPN-GATEWAY.README.md) - Advanced VPN configuration options
- [Certificate Management Guide](docs/client-certificate-management.md) - Managing certificates for VPN authentication

### Network Diagrams

To better understand the network architecture and components, refer to these diagrams:

- [High-Level Architecture](docs/diagrams/high-level-architecture.md) - Overview of the entire system
- [Point-to-Site VPN Connection Flow](docs/diagrams/point-to-site-vpn-connection-flow.md) - VPN connection process
- [Network Security Implementation](docs/diagrams/network-security.md) - Security components and configurations
- [NAT Gateway Configuration](docs/diagrams/nat-gateway-configuration.md) - Outbound internet access setup
- [Certificate Management Flow](docs/diagrams/certificate-management-flow.md) - Certificate creation and management
- [Subnet Layout](docs/diagrams/subnet-layout.md) - Detailed subnet configuration
- [Traffic Flow and Routing](docs/diagrams/traffic-flow-and-routing.md) - Network traffic patterns
- [Cost Optimization Strategy](docs/diagrams/cost-optimization-strategy.md) - Managing Azure costs

## Features

### Infrastructure Deployment

The deployment menu allows you to:
- Deploy the complete infrastructure (VNet, Subnets, VPN Gateway, NAT Gateway)
- Deploy individual components as needed
- Check deployment status

> **Note:** The VPN Gateway deployment can take 30-45 minutes to complete.

### Network Infrastructure

- Virtual Network with multiple subnets
- Network Security Groups for traffic control
- Gateway subnet for VPN connectivity
- Optional NAT Gateway for outbound internet access

See the [Subnet Layout](docs/diagrams/subnet-layout.md) diagram for details on the network structure.

### VPN Connectivity

- Point-to-Site VPN for secure remote access
- Multiple authentication methods (Certificate, Azure AD, RADIUS)
- Split tunneling options
- Custom DNS and routing configurations

For details on the VPN connection process, see the [Point-to-Site VPN Connection Flow](docs/diagrams/point-to-site-vpn-connection-flow.md) diagram.

### VPN Certificate Management

Easily manage certificates for your VPN connections:
- Create root certificates
- Generate client certificates
- Add certificates to the VPN Gateway
- List all certificates
- Certificate lifecycle management
- Secure certificate storage and distribution

The [Certificate Management Flow](docs/diagrams/certificate-management-flow.md) diagram illustrates this process.

### VPN Client Management

Configure and manage VPN clients:
- Add computers to the VPN
- Connect to and disconnect from the VPN
- Check VPN connection status

### NAT Gateway Management

Control the NAT Gateway to manage costs:
- Enable NAT Gateway when needed for outbound internet access
- Disable NAT Gateway when not in use to save costs
- Check NAT Gateway status

See the [NAT Gateway Configuration](docs/diagrams/nat-gateway-configuration.md) diagram for details.

### Monitoring & Alerting

Keep track of your environment:
- Monitor Azure resource usage and performance
- Track and analyze Azure costs
- Perform health checks on your HomeLab environment
- Set up alerts for important events or thresholds

## Usage Scenarios

This HomeLab environment is ideal for:

- Learning Azure networking concepts
- Testing secure remote access solutions
- Developing and testing cloud applications
- Simulating hybrid cloud scenarios
- Practicing Azure administration tasks

## Cost Management

- **VPN Gateway**: ~$27/month (Basic SKU)
- **NAT Gateway**: ~$32/month + data processing charges when enabled
- **Public IP addresses**: ~$3-5/month each

By keeping the NAT Gateway disabled when not in use, you can significantly reduce costs.

For detailed cost optimization strategies, see the [Cost Optimization Strategy](docs/diagrams/cost-optimization-strategy.md) diagram.

## Configuration Settings

The HomeLab setup allows you to configure:
- Environment (dev, test, prod)
- Location code for resource naming
- Project name for resource naming
- Azure location for resource deployment
- Log file location for troubleshooting

The default configuration file is stored at `$env:USERPROFILE\HomeLab\config.json`. You can modify settings through the Settings menu in the application.

## Project Structure

The HomeLab module is organized into the following directory structure:

```
HomeLab/
├── modules/
│   ├── HomeLab.Core/
│   ├── HomeLab.Azure/
│   ├── HomeLab.Security/
│   ├── HomeLab.UI/
│   └── HomeLab.Monitoring/
├── docs/
│   ├── diagrams/
│   │   ├── certificate-management-flow.md
│   │   ├── cost-optimization-strategy.md
│   │   ├── high-level-architecture.md
│   │   ├── nat-gateway-configuration.md
│   │   ├── network-security.md
│   │   ├── point-to-site-vpn-connection-flow.md
│   │   ├── subnet-layout.md
│   │   └── traffic-flow-and-routing.md
│   ├── PREREQUISITES.MD
│   ├── SETUP.md
│   ├── VPN-GATEWAY.README.md
│   └── client-certificate-management.md
├── HomeLab.psd1
├── HomeLab.psm1
└── README.md
```

## Troubleshooting

### VPN Connection Issues

1. Verify that the client certificate is properly installed:
   - Open "certmgr.msc"
   - Check under "Personal > Certificates" for your computer certificate
   - Check under "Trusted Root Certification Authorities > Certificates" for the VPN root certificate

2. Check VPN Gateway status in Azure Portal:
   - Navigate to your VPN Gateway resource
   - Check "Overview" page for status
   - Review "Point-to-site configuration" for proper setup

3. Review connection logs:
   - On Windows, check Event Viewer under "Applications and Services Logs > Microsoft > Windows > VPN"
   - Check the HomeLab log file specified in your configuration

For a detailed view of the network traffic flow, see the [Traffic Flow and Routing](docs/diagrams/traffic-flow-and-routing.md) diagram.

### NAT Gateway Issues

1. Verify subnet associations:
   - In Azure Portal, navigate to your virtual network
   - Check subnet configurations to confirm NAT Gateway association

2. Test connectivity:
   - Deploy a test VM in the subnet
   - Try to access internet resources
   - Check outbound IP using a service like ipinfo.io

## Module Documentation

Each module in the HomeLab system has its own README with detailed information:

- [HomeLab.Core](./modules/HomeLab.Core/README.md) - Foundation module with configuration, logging, and setup utilities
- [HomeLab.Azure](./modules/HomeLab.Azure/README.md) - Azure-specific functionality for resource deployment and management
- [HomeLab.Security](./modules/HomeLab.Security/README.md) - Security-related functionality including VPN and certificates
- [HomeLab.UI](./modules/HomeLab.UI/README.md) - User interface components including menus and handlers
- [HomeLab.Monitoring](./modules/HomeLab.Monitoring/README.md) - Monitoring and alerting capabilities

## PowerShell Module

This repository includes a PowerShell module with functions for:

- Deploying and managing Azure resources
- Creating and managing certificates
- Configuring VPN clients
- Monitoring and troubleshooting

## Contributing

Contributions to improve the HomeLab environment are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Microsoft Azure Documentation
- PowerShell Community
- Contributors to this project

## Support

For issues, questions, or suggestions, please open an issue in the GitHub repository.

## Author

Jurie Smit
