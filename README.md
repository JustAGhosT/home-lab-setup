# Azure Home Lab VPN Setup

This repository contains scripts for setting up and managing an Azure virtual network with VPN connectivity for a home lab environment.

## Overview

The setup includes:

- Azure Virtual Network with multiple subnets
- Azure VPN Gateway for secure remote access
- Azure NAT Gateway for outbound internet connectivity
- PowerShell module for managing the entire environment

## Prerequisites

- Azure CLI installed and configured
- Azure subscription with sufficient permissions
- PowerShell 5.1 or later
- Az PowerShell module installed (`Install-Module -Name Az -AllowClobber -Force`)

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

## Features

### Infrastructure Deployment

The deployment menu allows you to:
- Deploy the complete infrastructure (VNet, Subnets, VPN Gateway, NAT Gateway)
- Deploy individual components as needed
- Check deployment status

> **Note:** The VPN Gateway deployment can take 30-45 minutes to complete.

### VPN Certificate Management

Easily manage certificates for your VPN connections:
- Create root certificates
- Generate client certificates
- Add certificates to the VPN Gateway
- List all certificates

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

## Cost Management

- **VPN Gateway**: ~$27/month (Basic SKU)
- **NAT Gateway**: ~$32/month + data processing charges when enabled
- **Public IP addresses**: ~$3-5/month each

By keeping the NAT Gateway disabled when not in use, you can significantly reduce costs.

## Configuration Settings

The HomeLab setup allows you to configure:
- Environment (dev, test, prod)
- Location code for resource naming
- Project name for resource naming
- Azure location for resource deployment
- Log file location for troubleshooting

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

### NAT Gateway Issues

1. Verify subnet associations:
   - In Azure Portal, navigate to your virtual network
   - Check subnet configurations to confirm NAT Gateway association

2. Test connectivity:
   - Deploy a test VM in the subnet
   - Try to access internet resources
   - Check outbound IP using a service like ipinfo.io

## Documentation

The HomeLab setup includes comprehensive documentation:
- Main README with overview and setup instructions
- VPN Gateway documentation with detailed configuration options
- Client certificate management guide for secure access

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
