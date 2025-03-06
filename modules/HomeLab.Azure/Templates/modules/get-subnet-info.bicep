// Helper module to get subnet information

param vnetName string
param subnetName string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnetName}/${subnetName}'
}

output addressPrefix string = subnet.properties.addressPrefix
output subnetId string = subnet.id
