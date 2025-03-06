# HomeLab.Security

## Overview

HomeLab.Security provides security-related functionality for the HomeLab environment, including VPN certificate management, VPN gateway configuration, and VPN client setup.

## Features

- **Certificate Management**: Create and manage certificates for VPN authentication
- **VPN Gateway Configuration**: Configure the Azure VPN Gateway for secure remote access
- **VPN Client Setup**: Generate and configure VPN client profiles
- **Security Best Practices**: Implement security best practices for your home lab

## Functions

### Certificate Functions

- `New-RootCertificate`: Creates a new root certificate for VPN authentication
- `New-ClientCertificate`: Creates a client certificate signed by the root certificate
- `Export-Certificate`: Exports a certificate to a file
- `Import-Certificate`: Imports a certificate from a file
- `Get-CertificateThumbprint`: Gets the thumbprint of a certificate

### VPN Gateway Functions

- `Configure-VpnGateway`: Configures the VPN gateway with certificates
- `Update-VpnGatewaySettings`: Updates VPN gateway settings
- `Get-VpnGatewayStatus`: Gets the current status of the VPN gateway

### VPN Client Functions

- `New-VpnClientProfile`: Creates a new VPN client profile
- `Export-VpnClientProfile`: Exports a VPN client profile to a file
- `Import-VpnClientProfile`: Imports a VPN client profile from a file
- `Install-VpnClient`: Installs the VPN client on the local machine

## Installation

This module is part of the HomeLab system and is automatically loaded by the main HomeLab module. To use it independently:

```powershell
Import-Module -Name ".\HomeLab.Security.psm1"
# Note: HomeLab.Core must be loaded first
```

## Configuration

This module relies on configuration settings from HomeLab.Core, particularly:

- Certificate storage location
- VPN settings
- Security parameters

## Example Usage

```powershell
# Create a new root certificate
New-RootCertificate -Name "HomeLab-Root"

# Create a client certificate
New-ClientCertificate -Name "HomeLab-Client" -RootCertName "HomeLab-Root"

# Configure the VPN gateway
Configure-VpnGateway -RootCertThumbprint (Get-CertificateThumbprint -Name "HomeLab-Root")

# Create and export a VPN client profile
New-VpnClientProfile -Name "HomeLab-VPN"
Export-VpnClientProfile -Name "HomeLab-VPN" -Path "$env:USERPROFILE\Downloads"
```

## Dependencies

- HomeLab.Core module
- HomeLab.Azure module
- PowerShell 5.1 or higher

## Notes

This module handles security-sensitive operations. Ensure that certificates and VPN profiles are stored securely and that appropriate access controls are in place.
