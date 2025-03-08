targetScope = 'subscription'

@description('Location for all resources.')
param location string = 'southafricanorth'

@description('Environment prefix for resources.')
param env string = 'dev'

@description('Location abbreviation for resources.')
param loc string = 'saf'

@description('Project name for resources.')
param project string = 'homelab'

@description('Configuration object for the deployment')
param config object

@description('Current month in MM format')
param currentMonth string = utcNow('MM')

@description('Current year in yyyy format')
param currentYear string = utcNow('yyyy')

// Variables for resource naming
var prefix = '${env}-${loc}'
var rgName = '${prefix}-rg-${project}'

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

// Deploy network resources
module networkResources 'network.bicep' = {
  name: 'networkResources'
  scope: resourceGroup
  params: {
    location: location
    env: env
    loc: loc
    project: project
    vnetAddressPrefix: config.network.vnetAddressPrefix
    defaultSubnetPrefix: config.network.defaultSubnetPrefix
    appSubnetPrefix: config.network.appSubnetPrefix
    dbSubnetPrefix: config.network.dbSubnetPrefix
    enableNatGateway: contains(config, 'natGateway') ? config.natGateway.enabled : false
    enableVpnGateway: contains(config, 'vpn') ? config.vpn.enabled : false
  }
}

// Deploy monitoring resources if enabled
module monitoringResources 'monitoring.bicep' = if (contains(config, 'monitoring') && config.monitoring.enabled) {
  name: 'monitoringResources'
  scope: resourceGroup
  params: {
    location: location
    env: env
    loc: loc
    project: project
    emailAddress: contains(config.monitoring, 'alerts') && contains(config.monitoring.alerts, 'emailRecipients') ? first(config.monitoring.alerts.emailRecipients) : 'admin@example.com'
    existingVnetName: networkResources.outputs.virtualNetworkName
    existingNatGatewayName: networkResources.outputs.natGatewayName
    existingVpnGatewayName: networkResources.outputs.vpnGatewayName
    logRetentionInDays: contains(config.monitoring, 'dashboard') && contains(config.monitoring.dashboard, 'retentionDays') ? config.monitoring.dashboard.retentionDays : 30
    costAlertThreshold: 100
    currentMonth: currentMonth
    currentYear: currentYear
  }
  dependsOn: [
    networkResources
  ]
}

// Outputs
output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output virtualNetworkName string = networkResources.outputs.virtualNetworkName
output natGatewayName string = networkResources.outputs.natGatewayName
output vpnGatewayName string = networkResources.outputs.vpnGatewayName
