# HomeLab.Core Module

The HomeLab.Core module provides foundational functionality for the HomeLab system, including configuration management, logging, utility functions, and error handling.

## Overview

This module serves as the foundation for all other HomeLab modules and provides:

- **Configuration Management**: Centralized configuration loading and validation
- **Logging System**: Structured logging with multiple output targets
- **Utility Functions**: Common helper functions used across modules
- **Error Handling**: Standardized error handling and reporting
- **Setup Utilities**: Initial setup and environment validation

## Key Functions

### Configuration Management

#### `Get-HomeLabConfiguration`
Loads and validates the HomeLab configuration from the default or specified location.

```powershell
$config = Get-HomeLabConfiguration
$config = Get-HomeLabConfiguration -Path "C:\Custom\config.json"
```

#### `Set-HomeLabConfiguration`
Updates the HomeLab configuration with new values.

```powershell
Set-HomeLabConfiguration -Environment "prod" -LogLevel "Info"
```

#### `Test-HomeLabConfiguration`
Validates the current configuration for completeness and correctness.

```powershell
$isValid = Test-HomeLabConfiguration
```

### Logging System

#### `Write-HomeLabLog`
Writes structured log messages with different severity levels.

```powershell
Write-HomeLabLog -Message "Deployment started" -Level Info
Write-HomeLabLog -Message "Error occurred" -Level Error -Exception $_.Exception
```

#### `Initialize-HomeLabLogging`
Sets up the logging system with configured targets and formats.

```powershell
Initialize-HomeLabLogging -LogPath "C:\Logs\homelab.log" -Level Debug
```

### Utility Functions

#### `Test-HomeLabPrerequisites`
Validates that all required tools and permissions are available.

```powershell
$prereqCheck = Test-HomeLabPrerequisites
if (-not $prereqCheck.IsValid) {
    Write-Host "Missing prerequisites: $($prereqCheck.MissingItems -join ', ')"
}
```

#### `Get-HomeLabVersion`
Returns version information for the HomeLab module and its components.

```powershell
$version = Get-HomeLabVersion
Write-Host "HomeLab version: $($version.ModuleVersion)"
```

#### `Invoke-HomeLabSetup`
Performs initial setup and configuration of the HomeLab environment.

```powershell
Invoke-HomeLabSetup -Environment dev -Location eastus
```

## Configuration Schema

The HomeLab configuration file (`config.json`) supports the following structure:

```json
{
    "environment": "dev|staging|prod",
    "azure": {
        "subscriptionId": "subscription-guid",
        "tenantId": "tenant-guid",
        "location": "eastus"
    },
    "logging": {
        "level": "Debug|Info|Warning|Error",
        "targets": ["Console", "File", "EventLog"],
        "filePath": "path-to-log-file"
    },
    "networking": {
        "addressSpace": "10.0.0.0/16",
        "subnets": {
            "default": "10.0.1.0/24",
            "gateway": "10.0.2.0/24"
        }
    },
    "security": {
        "certificateStore": "path-to-cert-store",
        "keyVaultName": "key-vault-name"
    }
}
```

## Error Handling

The module provides standardized error handling through:

#### `New-HomeLabError`
Creates standardized error objects with context information.

```powershell
$error = New-HomeLabError -Message "Deployment failed" -Category ResourceUnavailable -TargetObject $resource
```

#### `Write-HomeLabError`
Logs and optionally throws errors in a consistent format.

```powershell
Write-HomeLabError -Message "Configuration invalid" -Throw
```

## Environment Variables

The module recognizes these environment variables:

- `HOMELAB_CONFIG_PATH`: Override default configuration file location
- `HOMELAB_LOG_LEVEL`: Override logging level
- `HOMELAB_ENVIRONMENT`: Override environment setting
- `HOMELAB_DEBUG`: Enable debug mode

## Dependencies

### Required PowerShell Modules
- **Az.Accounts** (>= 2.0.0): Azure authentication
- **Az.Profile** (>= 1.0.0): Azure profile management

### Optional Dependencies
- **PowerShell-Yaml**: YAML configuration support
- **ImportExcel**: Excel report generation

## Installation

The HomeLab.Core module is automatically loaded when importing the main HomeLab module:

```powershell
Import-Module HomeLab
```

For development or testing, you can import the module directly:

```powershell
Import-Module .\HomeLab\modules\HomeLab.Core\HomeLab.Core.psd1
```

## Testing

Run unit tests for the Core module:

```powershell
cd tests
.\Run-HomeLab-Tests.ps1 -TestType Unit | Where-Object { $_.Name -like "*Core*" }
```

## Examples

### Basic Setup
```powershell
# Initialize HomeLab with default settings
Import-Module HomeLab
$config = Get-HomeLabConfiguration
Initialize-HomeLabLogging

# Validate prerequisites
$prereqs = Test-HomeLabPrerequisites
if ($prereqs.IsValid) {
    Write-HomeLabLog "All prerequisites met" -Level Info
} else {
    Write-HomeLabLog "Missing prerequisites: $($prereqs.MissingItems -join ', ')" -Level Warning
}
```

### Custom Configuration
```powershell
# Set up custom environment
Set-HomeLabConfiguration -Environment "staging" -LogLevel "Debug"
$config = Get-HomeLabConfiguration

# Initialize with custom log path
Initialize-HomeLabLogging -LogPath "C:\HomeLab\Logs\staging.log" -Level Debug

# Perform setup
Invoke-HomeLabSetup -Environment staging -Location westus2
```

### Error Handling Example
```powershell
try {
    $result = Invoke-SomeOperation
    Write-HomeLabLog "Operation completed successfully" -Level Info
}
catch {
    $error = New-HomeLabError -Message "Operation failed" -Exception $_.Exception
    Write-HomeLabError -ErrorRecord $error -Throw
}
```

## Troubleshooting

### Common Issues

#### Configuration File Not Found
```
Error: Configuration file not found at default location
```
**Solution**: Create configuration file or specify custom path:
```powershell
$config = Get-HomeLabConfiguration -Path "C:\Custom\config.json"
```

#### Logging Initialization Fails
```
Error: Cannot initialize logging system
```
**Solution**: Check log file path permissions and disk space:
```powershell
Test-Path "C:\Logs" -PathType Container
```

#### Prerequisites Check Fails
```
Warning: Missing required tools or permissions
```
**Solution**: Install missing components:
```powershell
$prereqs = Test-HomeLabPrerequisites
$prereqs.MissingItems | ForEach-Object { Write-Host "Install: $_" }
```

## Contributing

When contributing to the HomeLab.Core module:

1. Follow PowerShell best practices
2. Add comprehensive error handling
3. Include parameter validation
4. Write unit tests for new functions
5. Update this documentation

## Related Modules

- **HomeLab.Azure**: Uses Core for configuration and logging
- **HomeLab.Security**: Depends on Core utilities
- **HomeLab.UI**: Uses Core for error handling and logging

## Support

For issues specific to the Core module:
1. Check the troubleshooting section above
2. Review the main [Troubleshooting Guide](../../../docs/TROUBLESHOOTING.md)
3. Open an issue in the GitHub repository