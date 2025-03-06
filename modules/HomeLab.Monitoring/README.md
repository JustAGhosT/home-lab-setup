# HomeLab.Monitoring

## Overview

HomeLab.Monitoring provides monitoring and alerting capabilities for your HomeLab environment. It helps track resource usage, costs, and system health.

## Features

- **Resource Monitoring**: Monitor Azure resource usage and performance
- **Cost Tracking**: Track and analyze Azure costs
- **Health Checks**: Perform health checks on your HomeLab environment
- **Alerting**: Set up alerts for important events or thresholds

## Functions

### Monitoring Functions

- `Start-ResourceMonitoring`: Starts monitoring Azure resources
- `Get-ResourceMetrics`: Gets performance metrics for Azure resources
- `Test-ResourceHealth`: Tests the health of Azure resources

### Cost Functions

- `Get-CurrentCosts`: Gets the current cost of Azure resources
- `Get-CostForecast`: Gets a forecast of future costs
- `Export-CostReport`: Exports a cost report to a file

### Health Check Functions

- `Invoke-HealthCheck`: Performs a health check on the HomeLab environment
- `Get-HealthStatus`: Gets the current health status of the HomeLab environment
- `Export-HealthReport`: Exports a health report to a file

### Alerting Functions

- `Set-AlertRule`: Sets up an alert rule
- `Get-AlertRules`: Gets the current alert rules
- `Remove-AlertRule`: Removes an alert rule
- `Test-AlertRule`: Tests an alert rule

## Installation

This module is part of the HomeLab system and is automatically loaded by the main HomeLab module. To use it independently:

```powershell
Import-Module -Name ".\HomeLab.Monitoring.psm1"
# Note: HomeLab.Core and HomeLab.Azure must be loaded first
```

## Configuration

This module relies on configuration settings from HomeLab.Core, particularly:

- Monitoring intervals
- Cost thresholds
- Health check parameters
- Alert settings

## Example Usage

```powershell
# Start resource monitoring
Start-ResourceMonitoring

# Get current costs
$costs = Get-CurrentCosts

# Perform a health check
$healthStatus = Invoke-HealthCheck

# Set up an alert rule
Set-AlertRule -Name "HighCPU" -Metric "CPU" -Threshold 90 -Operator "GreaterThan"
```

## Dependencies

- HomeLab.Core module
- HomeLab.Azure module
- Az PowerShell module (9.0.0 or higher)
- PowerShell 5.1 or higher

## Notes

This module is designed to help you monitor and maintain your HomeLab environment. Regular monitoring can help identify issues before they become problems and keep costs under control.
