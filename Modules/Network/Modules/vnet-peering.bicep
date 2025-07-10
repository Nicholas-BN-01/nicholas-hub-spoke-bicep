param resourceNames object

param hubVnetName string
param hubVnetID string
param spokeVnetName string
param spokeVnetID string

resource hubNetworkExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: hubVnetName
  scope: resourceGroup()
}

resource spokeNetworkExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: spokeVnetName
  scope: resourceGroup()
}

resource hubSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hubNetworkExisting
  name: resourceNames.network.hubPeering
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetID
    }
  }
}

resource spokeHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spokeNetworkExisting
  name: resourceNames.network.spokePeering
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVnetID
    }
  }
}
