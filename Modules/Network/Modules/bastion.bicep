param resourceNames object
param resourceLocation string

resource azureBastionPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: resourceNames.network.azureBastionPublicIP
  location: resourceLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    ddosSettings: {
      protectionMode: 'Disabled'
    }
    publicIPAddressVersion: 'IPv4'
  }
}

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource subnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'azureBastionSubnet'
}

resource azureBastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: resourceNames.network.azureBastion
  location: resourceLocation
  sku: {
    name: 'Basic'
  }
  properties: {
    enableKerberos: false
    ipConfigurations: [
      {
        name: 'bastionIPconfig'
        properties: {
          publicIPAddress: {
            id: azureBastionPublicIP.id
          }
          subnet: {
            id: subnetExisting.id
          }
        }
      }
    ]
  }
}
