param resourceNames object
param resourceLocation string

param adminUsername string
@secure()
param adminPassword string

param vmName string
param vmPrivateIPAddress string
param vmZone string
param vmSize string
param osDiskSize int
param osDiskType string
param osVersion string

param backupEnabled bool
param sqlEnabled bool
param sqlServerLicense string

var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource hubVMSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'VMSubnet'
}

resource testVMSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'TestSubnet'
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
          subnet: {
            id: (vmName == 'hub-vm') ? hubVMSubnetExisting.id : testVMSubnetExisting.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: vmPrivateIPAddress
          primary: true
        }
      }
    ]
  }
}

resource vmNSG 'Microsoft.Network/networkSecurityGroups@2024-07-01' = if (vmName == 'hub-vm') {
  location: resourceLocation
  name: 'nsg-${vmName}'
  properties: {
    flushConnection: false
    securityRules: [
      {
        name: 'Allow-SSH-VPN'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: vmPrivateIPAddress
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 120
          protocol: '*'
          sourceAddressPrefix: '172.16.0.0/24'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Deny-AKS-Out'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '10.10.1.0/24'
          destinationPortRange: '*'
          direction: 'Outbound'
          priority: 110
          protocol: '*'
          sourceAddressPrefix: vmPrivateIPAddress
          sourcePortRange: '*'
        }
      }
      {
        name: 'Deny-Files-Out'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '10.10.2.0/24'
          destinationPortRange: '*'
          direction: 'Outbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: vmPrivateIPAddress
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: resourceLocation
  zones: [vmZone]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      diskControllerType: 'SCSI'
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        caching: 'ReadOnly'
        managedDisk:{
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[osVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceCard.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

output privateIPVmVnet string = networkInterfaceCard.properties.ipConfigurations[0].properties.privateIPAddress
