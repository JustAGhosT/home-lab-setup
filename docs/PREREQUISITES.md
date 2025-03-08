# HomeLab Setup Prerequisites

This document outlines all prerequisites required before deploying your Azure HomeLab environment, including subscription requirements, local tools, and permissions.

## Azure Subscription Requirements

- **Active Azure Subscription**: Pay-As-You-Go, Visual Studio subscription, or Azure for Students
- **Sufficient Quota**: Ensure you have quota for the following resources:
  - Virtual Networks: At least 1
  - Public IP Addresses: At least 2
  - Virtual Network Gateways: At least 1 (VPN Gateway)
  - Virtual Machines: Based on your lab requirements

## Required Local Tools

### Core Tools
- **Azure CLI**: Version 2.40.0 or higher
  ```powershell
  # Check version
  az --version
  
  # Install or update
  winget install -e --id Microsoft.AzureCLI
  ```

- **PowerShell**: Version 7.2 or higher
  ```powershell
  # Check version
  $PSVersionTable.PSVersion
  
  # Install or update
  winget install Microsoft.PowerShell
  ```

- **Az PowerShell Module**: Version 9.0.0 or higher
  ```powershell
  # Check version
  Get-InstalledModule -Name Az
  
  # Install or update
  Install-Module -Name Az -Force -AllowClobber -Repository PSGallery
  ```

### Optional Tools
- **Visual Studio Code**: For editing configuration files
  ```powershell
  winget install -e --id Microsoft.VisualStudioCode
  ```

- **Azure Storage Explorer**: For managing storage accounts
  ```powershell
  winget install -e --id Microsoft.AzureStorageExplorer
  ```

- **OpenSSL**: For certificate management (if not using PowerShell for certificates)
  ```powershell
  winget install -e --id ShiningLight.OpenSSL
  ```

## Required Permissions

### Azure Permissions
- **Owner** or **Contributor** role on the subscription or resource group
- **User Access Administrator** role if you plan to create custom roles or assign permissions

### Local Machine Permissions
- **Administrator access** for certificate creation and management
- **PowerShell execution policy** that allows running scripts:
  ```powershell
  # Check current execution policy
  Get-ExecutionPolicy
  
  # Set to allow signed scripts (recommended)
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Network Requirements

- **Outbound internet access** for Azure CLI and PowerShell modules
- **Port 443 (HTTPS)** open for outbound connections
- **VPN client support** on your local machine for testing Point-to-Site VPN connections

## Pre-Deployment Checklist

- [ ] Azure subscription is active and has sufficient quota
- [ ] Required tools are installed and updated
- [ ] You have the necessary permissions in Azure
- [ ] Your local machine meets all requirements
- [ ] You have downloaded this repository and navigated to the root folder
- [ ] You have reviewed the configuration files and modified as needed

## Next Steps

Once all prerequisites are met, proceed to the [Setup Guide](SETUP.md) to deploy your HomeLab environment.
