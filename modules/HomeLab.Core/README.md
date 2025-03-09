# HomeLab.Core

## Overview

HomeLab.Core is the foundation module for the [HomeLab system](../../README.md). It provides essential functionality for configuration management, logging, prerequisites checking, and initial setup that other modules depend on.

## Features

- **Configuration Management**: Load, save, and reset configuration settings
- **Logging System**: Structured logging with multiple severity levels
- **Prerequisites Management**: Check and install required dependencies
- **Setup Utilities**: First-time setup and initialization functions

## Functions

### Configuration Functions

- `Get-Configuration`: Retrieves the current configuration object
- `Import-Configuration`: Loads configuration from the config file
- `Save-Configuration`: Saves current configuration to the config file
- `Reset-Configuration`: Resets configuration to default values
- `Update-ConfigurationParameter`: Updates a specific configuration parameter

### Logging Functions

- `Initialize-Logging`: Sets up the log file for the application
- `Write-Log`: Writes a log entry with specified severity level
- `Get-LogPath`: Returns the current log file path

### Prerequisites Functions

- `Test-Prerequisites`: Checks if all required prerequisites are installed
- `Install-Prerequisites`: Installs missing prerequisites
- `Get-PrerequisitesList`: Returns a list of required prerequisites

### Setup Functions

- `Initialize-HomeLab`: Performs first-time setup for HomeLab
- `Test-SetupComplete`: Checks if initial setup has been completed

## Installation

This module is part of the HomeLab system and is automatically loaded by the main HomeLab module. To use it independently:

```powershell
Import-Module -Name ".\HomeLab.Core.psm1"
```

## Configuration

The default configuration file is stored at `$env:USERPROFILE\HomeLab\config.json`. The configuration includes:

- Environment settings (dev, test, prod)
- Location codes
- Project name
- Azure location
- Log file path
- Other system settings

## Example Usage

```powershell
# Load configuration
Import-Configuration

# Get current configuration
$config = Get-Configuration

# Update a configuration parameter
Update-ConfigurationParameter -Name "env" -Value "dev"

# Save configuration changes
Save-Configuration

# Write a log entry
Write-Log -Message "Configuration updated" -Level INFO
```

## Dependencies

- PowerShell 5.1 or higher

## Related Modules

- [HomeLab.Azure](../HomeLab.Azure/README.md) - Uses Core for configuration and logging
- [HomeLab.Security](../HomeLab.Security/README.md) - Uses Core for configuration and logging
- [HomeLab.UI](../HomeLab.UI/README.md) - Uses Core for configuration and logging
- [HomeLab.Monitoring](../HomeLab.Monitoring/README.md) - Uses Core for configuration and logging

## Notes

This is a core module that other HomeLab modules depend on. It should be loaded first in the module loading sequence.

[Back to main README](../../README.md)
