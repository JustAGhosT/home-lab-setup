@description('Location for all resources.')
param location string = 'southafricanorth'

@description('Environment prefix for resources.')
param env string = 'dev'

@description('Location abbreviation for resources.')
param loc string = 'saf'

@description('Project name for resources.')
param project string = 'homelab'

@description('Number of days to retain logs.')
param logRetentionInDays int = 30

@description('Email address for alert notifications.')
param emailAddress string

@description('Cost threshold in USD for budget alerts.')
param costAlertThreshold int = 50

@description('Name of the existing virtual network.')
param existingVnetName string

@description('Name of the existing VPN gateway, if deployed.')
param existingVpnGatewayName string = ''

@description('Name of the existing NAT gateway.')
param existingNatGatewayName string

@description('Current year for budget start date')
param currentYear string = utcNow('yyyy')

@description('Current month for budget start date')
param currentMonth string = utcNow('MM')

// Variables for resource naming
var prefix = '${env}-${loc}'
var lawName = '${prefix}-law-${project}'
var actionGroupName = '${prefix}-ag-${project}'
var dashboardName = '${prefix}-dash-${project}'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: lawName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Action Group for Alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2021-09-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'HomeLab'
    enabled: true
    emailReceivers: [
      {
        name: 'Email Notification'
        emailAddress: emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

// Reference existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: existingVnetName
}

// Configure diagnostic settings for Virtual Network
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${existingVnetName}-diagnostics'
  scope: vnet
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Reference existing NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2021-05-01' existing = {
  name: existingNatGatewayName
}

// Configure diagnostic settings for NAT Gateway
resource natGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${existingNatGatewayName}-diagnostics'
  scope: natGateway
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ErrorLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Reference and configure VPN Gateway diagnostics if it exists
module vpnGatewayDiagnostics 'modules/conditional-vpn-diagnostics.bicep' = if (!empty(existingVpnGatewayName)) {
  name: 'vpnGatewayDiagnostics'
  params: {
    vpnGatewayName: existingVpnGatewayName
    workspaceId: logAnalyticsWorkspace.id
  }
}

// NAT Gateway SNAT Port Utilization Alert
resource natPortUtilizationAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${prefix}-alert-nat-port-utilization-${project}'
  location: 'global'
  properties: {
    description: 'Alert when NAT Gateway SNAT port utilization exceeds 80%'
    severity: 2
    enabled: true
    scopes: [
      natGateway.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'SnatPortUtilization'
          metricName: 'SNATPortUtilization'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Cost Alert (Budget)
resource costAlert 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: '${prefix}-budget-${project}'
  scope: resourceGroup()
  properties: {
    category: 'Cost'
    amount: costAlertThreshold
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${currentYear}-${currentMonth}-01'
    }
    filter: {}
    notifications: {
      actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          emailAddress
        ]
        thresholdType: 'Actual'
      }
      forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          emailAddress
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}

// Custom Dashboard
resource dashboard 'Microsoft.Portal/dashboards@2022-12-01-preview' = {
  name: dashboardName
  location: location
  tags: {
    'hidden-title': 'HomeLab Monitoring Dashboard'
  }
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              type: any('Extension/HubsExtension/PartType/MonitorChartPart')
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: natGateway.id
                          }
                          name: 'SNATPortUtilization'
                          aggregationType: 4
                        }
                      ]
                      title: 'NAT Gateway SNAT Port Utilization'
                      visualization: {
                        chartType: 2
                      }
                    }
                  }
                }
              ]
            }
          }
          {
            position: {
              x: 6
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              type: any('Extension/HubsExtension/PartType/MonitorChartPart')
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: natGateway.id
                          }
                          name: 'SNATPortUtilization'
                          aggregationType: 4
                        }
                      ]
                      title: 'NAT Gateway SNAT Port Utilization'
                      visualization: {
                        chartType: 2
                      }
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    ]
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output actionGroupId string = actionGroup.id
output dashboardId string = dashboard.id
