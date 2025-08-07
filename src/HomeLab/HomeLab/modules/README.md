# HomeLab

## Overview

HomeLab is a comprehensive PowerShell module for deploying and managing a home lab environment in Azure. It provides a modular architecture with components for core functionality, Azure infrastructure, security, user interface, and monitoring.

## Features

- **Modular Architecture**: Clean separation of concerns with specialized modules
- **Azure Infrastructure**: Deploy and manage Azure resources for your home lab
- **VPN Setup**: Secure remote access to your home lab environment
- **NAT Gateway**: Control outbound internet access
- **User-Friendly Interface**: Interactive menu system for easy management
- **Monitoring & Alerting**: Track resource usage, costs, and system health

## Modules

- **HomeLab.Core**: Foundation module with configuration, logging, and setup utilities
- **HomeLab.Azure**: Azure-specific functionality for resource deployment and management
- **HomeLab.Security**: Security-related functionality including VPN and certificates
- **HomeLab.UI**: User interface components including menus and handlers
- **HomeLab.Monitoring**: Monitoring and alerting capabilities

## Installation

### Prerequisites

- PowerShell 5.1 or higher
- Az PowerShell module (9.0.0 or higher)

### Installation Steps

1. Clone the repository:
   ```powershell
   git clone https://github.com/JustAGhosT/home-lab-setup.git
   ```

2. Navigate to the directory:
   ```powershell
   cd home-lab-setup
   ```

3. Import the module:
   ```powershell
   Import-Module -Name ".\HomeLab.psd1"
   ```

## Usage

Start the HomeLab application:

```powershell
Start-HomeLab
```

This will launch the interactive menu system where you can:

- Deploy Azure infrastructure
- Set up VPN certificates and gateway
- Configure VPN clients
- Manage NAT gateway
- Generate documentation
- Configure settings

## Structure

The HomeLab module is organized into the following directory structure:

```
HomeLab/
├── modules/
│   ├── HomeLab.Core/
│   ├── HomeLab.Azure/
│   ├── HomeLab.Security/
│   ├── HomeLab.UI/
│   └── HomeLab.Monitoring/
├── HomeLab.psd1
├── HomeLab.psm1
└── README.md
```

## Configuration

The default configuration file is stored at `$env:USERPROFILE\HomeLab\config.json`. You can modify settings through the Settings menu in the application.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Jurie Smit

## Acknowledgments

- Thanks to the Azure PowerShell team for the excellent Az module
- Thanks to the PowerShell community for inspiration and support
