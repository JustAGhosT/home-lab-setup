# HomeLab.UI

## Overview

HomeLab.UI provides the user interface components for the HomeLab system, including menus, handlers, and helper functions for user interaction.

## Features

- **Menu System**: Interactive menu system for navigating the HomeLab application
- **Input Handlers**: Functions to process user input and execute corresponding actions
- **UI Helpers**: Helper functions for consistent UI formatting and interaction
- **User Experience**: Streamlined user experience for managing the HomeLab environment

## Components

### Menu Components

- `Show-MainMenu`: Displays the main menu
- `Show-DeployMenu`: Displays the deployment menu
- `Show-VpnCertMenu`: Displays the VPN certificate menu
- `Show-VpnGatewayMenu`: Displays the VPN gateway menu
- `Show-VpnClientMenu`: Displays the VPN client menu
- `Show-NatGatewayMenu`: Displays the NAT gateway menu
- `Show-DocumentationMenu`: Displays the documentation menu
- `Show-SettingsMenu`: Displays the settings menu

### Handler Components

- `Invoke-DeployMenu`: Handles deployment menu selections
- `Invoke-VpnCertMenu`: Handles VPN certificate menu selections
- `Invoke-VpnGatewayMenu`: Handles VPN gateway menu selections
- `Invoke-VpnClientMenu`: Handles VPN client menu selections
- `Invoke-NatGatewayMenu`: Handles NAT gateway menu selections
- `Invoke-DocumentationMenu`: Handles documentation menu selections
- `Invoke-SettingsMenu`: Handles settings menu selections

### Helper Functions

- `Write-MenuHeader`: Writes a formatted menu header
- `Write-MenuItem`: Writes a formatted menu item
- `Get-UserConfirmation`: Gets confirmation from the user
- `Pause`: Pauses execution until the user presses a key
- `Show-Progress`: Shows a progress bar for long-running operations

## Installation

This module is part of the HomeLab system and is automatically loaded by the main HomeLab module. To use it independently:

```powershell
Import-Module -Name ".\HomeLab.UI.psm1"
# Note: HomeLab.Core must be loaded first
```

## Structure

The UI module is organized into the following directory structure:

```
HomeLab.UI/
├── Public/
│   ├── menu/
│   │   ├── 1-MainMenu.ps1
│   │   ├── 2-DeployMenu.ps1
│   │   └── ...
│   ├── handlers/
│   │   ├── 1-DeployHandler.ps1
│   │   ├── 2-VpnCertHandler.ps1
│   │   └── ...
├── Private/
│   ├── Helpers.ps1
│   └── ...
└── HomeLab.UI.psm1
```

## Example Usage

```powershell
# Show the main menu
Show-MainMenu

# Handle settings menu selections
Invoke-SettingsMenu

# Get confirmation from the user
if (Get-UserConfirmation -Message "Are you sure you want to proceed?") {
    # User confirmed
}
```

## Dependencies

- HomeLab.Core module
- PowerShell 5.1 or higher

## Notes

This module provides the user interface for the HomeLab system. It depends on the other modules to perform the actual operations selected by the user.
