param resourceNames object
param resourceLocation string
param networkConfiguration object
param routeTableID string
param gatewayRouteTableID string

resource vnetDeploy 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: resourceNames.network.hubNetwork
  location: resourceLocation
  properties: {
    addressSpace: {
      addressPrefixes: networkConfiguration.hubNetwork.addressSpaces
    }
    dhcpOptions: {
      dnsServers: networkConfiguration.hubNetwork.dnsServers
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: networkConfiguration.hubNetwork.subnets.azureBastionSubnet
        }
      }
    ]
  }
}
