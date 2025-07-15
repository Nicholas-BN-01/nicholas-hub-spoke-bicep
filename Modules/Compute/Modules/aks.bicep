param resourceNames object
param resourceLocation string

param aksName string
param aksManagedIdentityID string
param aksConfig object
param aksPrivateDNSZoneID string

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource aksNodeSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'AKSSubnet'
}


