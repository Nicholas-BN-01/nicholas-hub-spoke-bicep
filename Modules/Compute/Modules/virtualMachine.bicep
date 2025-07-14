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

var vpnRangeIP = '172.16.0.0/24'
var hubRangeIP = '10.0.0.0/16'
var spokeRangeIP = '10.10.0.0/16'

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

resource DNSVmSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'DNSSubnet'
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
            id: (vmName == 'hub-vm') ? hubVMSubnetExisting.id : (vmName == 'test-vm') ? testVMSubnetExisting.id : DNSVmSubnetExisting.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: vmPrivateIPAddress
          primary: true
        }
      }
    ]
    networkSecurityGroup: (vmName == 'hub-vm') ? { id: vmNSG.id } : (vmName == 'dns-vm') ? { id: dnsNsg.id } : null
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
          sourceAddressPrefix: vpnRangeIP
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

resource dnsNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = if (vmName == 'dns-vm') {
  name: 'nsg-${vmName}'
  location: resourceLocation
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
          priority: 100
          protocol: '*'
          sourceAddressPrefix: vpnRangeIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-DNS-Hub-Inbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: vmPrivateIPAddress
          destinationPortRange: '53'
          direction: 'Inbound'
          priority: 110
          protocol: '*'
          sourceAddressPrefix: hubRangeIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-DNS-Spoke-Inbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: vmPrivateIPAddress
          destinationPortRange: '53'
          direction: 'Inbound'
          priority: 120
          protocol: '*'
          sourceAddressPrefix: spokeRangeIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-DNS-VPN-Inbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: vmPrivateIPAddress
          destinationPortRange: '53'
          direction: 'Inbound'
          priority: 130
          protocol: '*'
          sourceAddressPrefix: vpnRangeIP
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

resource dnsVmCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = if (vmName == 'dns-vm') {
  name: 'dnsScriptExtension'
  parent: vm
  location: resourceLocation
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'echo IyEvYmluL2Jhc2gKc3VkbyBhcHQgdXBkYXRlCgpzdWRvIHN5c3RlbWN0bCBlbmFibGUgc3lzdGVtZC1yZXNvbHZlZApzdWRvIHN5c3RlbWN0bCBzdGFydCBzeXN0ZW1kLXJlc29sdmVkCgpjYXQgPDxFT0YgPiAvZXRjL25ldHBsYW4vNTAtY2xvdWQtaW5pdC55YW1sCm5ldHdvcms6CnZlcnNpb246IDIKZXRoZXJuZXRzOgogICAgZXRoMDoKICAgIGRoY3A0OiB0cnVlCiAgICBuYW1lc2VydmVyczoKICAgICAgICBhZGRyZXNzZXM6IFsxNjguNjMuMTI5LjE2XQoKRU9GCgpzdWRvIG5ldHBsYW4gYXBwbHkKCnN1ZG8gc3lzdGVtY3RsIHJlc3RhcnQgc3lzdGVtZC1yZXNvbHZlZA== | base64 -d | bash'
    }
  }
}

output privateIPVmVnet string = networkInterfaceCard.properties.ipConfigurations[0].properties.privateIPAddress
