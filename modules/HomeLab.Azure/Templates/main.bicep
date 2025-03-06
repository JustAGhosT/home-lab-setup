targetScope = 'subscription'

@description('Location for all resources.')
param location string = 'southafricanorth'

@description('Environment prefix for resources.')
param env string = 'dev'

@description('Location abbreviation for resources.')
param loc string = 'saf'

@description('Project name for resources.')
param project string = 'homelab'

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
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
