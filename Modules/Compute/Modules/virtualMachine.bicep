param resourceNames object
param resourceLocation string

param adminUsername string
@secure()
param admimPassword string

param vmName string
param vmSubnet string
param vmPrivateIPAddress string

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource hubVMSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'azureVMSubnet'
}

resource testVMSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'azureTestSubnet'
}

resource networkInterfaceCard 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${vmName}'
  location: resourceLocation
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: (vmName == 'hub-vm') ? hubVMSubnetExisting : spokeVnetExisting
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: vmPrivateIPAddress
          primary: true
        }
      }
    ]
  }
}


