# HomeLab Setup Guide

This guide provides step-by-step instructions for deploying your Azure HomeLab environment, including network infrastructure, VPN gateway, and supporting services.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Network Infrastructure Deployment](#network-infrastructure-deployment)
- [VPN Gateway Deployment](#vpn-gateway-deployment)
- [Certificate Management](#certificate-management)
- [Client Configuration](#client-configuration)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)

## Initial Setup

### 1. Clone the Repository

```powershell
git clone https://github.com/YourUsername/AzureHomeLab.git
cd AzureHomeLab
```

### 2. Connect to Azure

```powershell
# Login to Azure
Connect-AzAccount

# Set the subscription context
$subscriptionId = "your-subscription-id"
Set-AzContext -SubscriptionId $subscriptionId
```

### 3. Configure Environment Variables

```powershell
# Set environment variables
$env:PROJECT_NAME = "homelab"
$env:LOCATION = "eastus"
$env:ENVIRONMENT = "dev"

# Or use the configuration script
.\scripts\Set-EnvironmentConfig.ps1 -ProjectName "homelab" -Location "eastus" -Environment "dev"
```

## Network Infrastructure Deployment

### 1. Create Resource Group

```powershell
# Create the main resource group
$resourceGroup = "$($env:ENVIRONMENT)-$($env:LOCATION)-rg-$($env:PROJECT_NAME)"
New-AzResourceGroup -Name $resourceGroup -Location $env:LOCATION
```

### 2. Deploy Virtual Network

```powershell
# Deploy the virtual network using the deployment script
.\scripts\Deploy-NetworkInfrastructure.ps1
```

This script deploys:
- Virtual Network with address space 10.0.0.0/16
- Default subnet (10.0.0.0/24)
- Application subnet (10.0.1.0/24)
- Gateway subnet (10.0.255.0/27)
- Network Security Groups
- NAT Gateway (optional)

## VPN Gateway Deployment

### 1. Create Certificates for VPN Authentication

```powershell
# Generate VPN certificates
.\scripts\Create-VpnClientCertificates.ps1
```

This script:
- Creates a root certificate
- Creates a client certificate
- Exports certificates to the specified path
- Outputs the base64-encoded root certificate for Azure configuration

### 2. Deploy VPN Gateway

```powershell
# Deploy the VPN Gateway
.\scripts\Deploy-VpnGateway.ps1
```

This script:
- Creates a public IP address for the VPN Gateway
- Deploys a Basic or VpnGw1 SKU VPN Gateway
- Configures point-to-site settings with the certificate data
- Sets up client address pool and protocols

> **Note**: VPN Gateway deployment can take 30-45 minutes to complete.

## Certificate Management

For detailed certificate management instructions, refer to the [Client Certificate Management Guide](client-certificate-management.md).

Key operations include:
- Creating additional client certificates
- Revoking certificates
- Exporting certificates for client devices

## Client Configuration

### 1. Download VPN Client Configuration

```powershell
# Generate and download VPN client configuration
.\scripts\Get-VpnClientPackage.ps1
```

### 2. Install Client Certificate

1. Double-click the `.pfx` file exported during certificate creation
2. Follow the Certificate Import Wizard
3. Install the certificate in the "Personal" certificate store

### 3. Install VPN Client Configuration

1. Extract the downloaded VPN client configuration package
2. Run the appropriate installer for your platform:
   - Windows: Run the `.exe` installer
   - Other platforms: Follow platform-specific instructions

## Testing and Validation

### 1. Connect to VPN

1. Open Network & Internet settings
2. Click on VPN
3. Select the newly added VPN connection
4. Click Connect
5. If prompted, select the client certificate

### 2. Verify Connectivity

```powershell
# Test connectivity to internal resources
Test-NetConnection -ComputerName "10.0.0.4" -Port 3389

# Check routing table
route print
```

## Troubleshooting

If you encounter issues during deployment or connection:

1. Check the [VPN Gateway Documentation](networking/vpn-gateway.md) for common issues and solutions
2. Review the [Troubleshooting](#troubleshooting) section of the VPN Gateway guide
3. Verify certificates are correctly installed and not expired
4. Check Azure resource health in the Azure Portal
5. Review VPN Gateway diagnostic logs

For additional assistance, please file an issue in the GitHub repository.

## Next Steps

After successful deployment, consider:

1. Deploying virtual machines in the lab environment
2. Setting up a domain controller
3. Implementing additional security measures
4. Exploring advanced VPN configurations

Refer to the [VPN Gateway Advanced Configuration Guide](networking/vpn-gateway.md) for more options.
