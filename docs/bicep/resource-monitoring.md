# Resource Monitoring Template

This document details the Bicep template used for configuring monitoring and diagnostics for the HomeLab environment.

## Template Purpose

The Resource Monitoring template (`monitoring.bicep`) configures Azure Monitor resources and diagnostic settings for the HomeLab environment. This enables visibility into resource performance, health, and usage patterns.

## Resource Components

### Log Analytics Workspace

The template deploys a Log Analytics workspace to centralize logs and metrics:

- **Name**: `{env}-{loc}-law-{project}` (e.g., `dev-saf-law-homelab`)
- **SKU**: PerGB2018 (pay-as-you-go pricing)
- **Retention**: 30 days (customizable)

### Diagnostic Settings

The template configures diagnostic settings for key resources:

1. **Virtual Network Diagnostics**
   - Logs: NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter
   - Metrics: AllMetrics
   - Destination: Log Analytics workspace

2. **VPN Gateway Diagnostics**
   - Logs: GatewayDiagnosticLog, TunnelDiagnosticLog, RouteDiagnosticLog, IKEDiagnosticLog, P2SDiagnosticLog
   - Metrics: AllMetrics
   - Destination: Log Analytics workspace

3. **NAT Gateway Diagnostics**
   - Logs: All available logs
   - Metrics: AllMetrics
   - Destination: Log Analytics workspace

### Azure Monitor Action Group

An action group for alerting is configured:

- **Name**: `{env}-{loc}-ag-{project}` (e.g., `dev-saf-ag-homelab`)
- **Short Name**: HomeLab
- **Notification Type**: Email (customizable)

### Alert Rules

The template creates several alert rules for monitoring the environment:

1. **VPN Gateway Connection Alert**
   - Triggers when P2S connections exceed threshold
   - Severity: 2 (Warning)
   - Evaluation frequency: 5 minutes

2. **NAT Gateway SNAT Port Utilization Alert**
   - Triggers when port utilization exceeds 80%
   - Severity: 2 (Warning)
   - Evaluation frequency: 5 minutes

3. **Cost Alert**
   - Triggers when estimated costs exceed threshold
   - Scope: Resource group
   - Threshold: $50 (customizable)

## Parameters

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| location | southafricanorth | Azure region for resource deployment |
| env | dev | Environment prefix (dev, test, prod) |
| loc | saf | Location abbreviation for resource naming |
| project | homelab | Project name for resource naming |
| logRetentionInDays | 30 | Number of days to retain logs |
| emailAddress | (required) | Email address for alert notifications |
| costAlertThreshold | 50 | Cost threshold in USD for budget alerts |
| existingVnetName | (required) | Name of the existing virtual network |
| existingVpnGatewayName | (required) | Name of the existing VPN gateway |
| existingNatGatewayName | (required) | Name of the existing NAT gateway |

## Outputs

The template outputs the following values:

- Log Analytics Workspace ID
- Action Group ID

## Usage Example

```powershell
# Deploy using Azure PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "dev-saf-rg-homelab" `
  -TemplateFile "./monitoring.bicep" `
  -emailAddress "user@example.com" `
  -existingVnetName "dev-saf-vnet-homelab" `
  -existingVpnGatewayName "dev-saf-vpng-homelab" `
  -existingNatGatewayName "dev-saf-ng-homelab" `
  -costAlertThreshold 75
```

## Dashboard Integration

The template includes a custom Azure dashboard for visualizing HomeLab metrics:

- **Name**: `{env}-{loc}-dash-{project}` (e.g., `dev-saf-dash-homelab`)
- **Type**: Private dashboard
- **Content**: JSON definition with tiles for:
  - VPN connection status
  - NAT Gateway metrics
  - Cost analysis
  - Resource health

## Cost Considerations

- Log Analytics workspace incurs costs based on data ingestion
- Configurable log retention period to control storage costs
- Cost alerts help prevent unexpected charges

## Customization Options

- Adjust log retention period based on requirements
- Modify alert thresholds for different sensitivity levels
- Add additional diagnostic settings for other resources
- Customize dashboard layout and metrics
