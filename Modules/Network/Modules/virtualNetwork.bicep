param resourceNames object
param resourceLocation string
param networkConfiguration object
param routeTableID string
param gatewayRouteTableID string
param vmRouteTableID string

resource hubVnetDeploy 'Microsoft.Network/virtualNetworks@2024-05-01' = {
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
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: networkConfiguration.hubNetwork.subnets.azureFirewallSubnet
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: networkConfiguration.hubNetwork.subnets.azureFirewallManagementSubnet
        }
      }
      {
        name: 'VPNGatewaySubnet'
        properties: {
          addressPrefix: networkConfiguration.hubNetwork.subnets.azureGatewaySubnet
          routeTable: {
            id: gatewayRouteTableID
          }
        }
      }
      {
        name: 'VMSubnet'
        properties: {
          addressPrefix: networkConfiguration.hubNetwork.subnets.azureVMSubnet
          routeTable: {
            id: vmRouteTableID
          }
        }
      }
    ]
  }
}

resource spokeVnetDeploy 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: resourceNames.network.spokeNetwork
  location: resourceLocation
  properties: {
    addressSpace: {
      addressPrefixes: networkConfiguration.spokeNetwork.addressSpaces
    }
    dhcpOptions: {
      dnsServers: networkConfiguration.spokeNetwork.dnsServers
    }
    subnets: [
      {
        name: 'AKSSubnet'
        properties: {
          addressPrefix: networkConfiguration.spokeNetwork.azureAKSSubnet
          routeTable: {
            id: routeTableID
          }
        }
      }
      {
        name: 'FilesEndpointSubnet'
        properties: {
          addressPrefix: networkConfiguration.spokeNetwork.azureFilesEndpointSubnet
          routeTable: {
            id: routeTableID
          }
        }
      }
      {
        name: 'TestSubnet'
        properties: {
          addressPrefix: networkConfiguration.spokeNetwork.azureTestSubnet
          routeTable: {
            id: routeTableID
          }
        }
      }
    ]
  }
}
