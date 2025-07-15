using 'main.bicep'

param resourceLocation = 'italynorth'

var customerInfo = {
  customerName: 'nicholas'
  projectName: 'hub-spoke'
}

var azureRgSuffix = '${customerInfo.customerName}-${customerInfo.projectName}'

param resourceNames = {
  network: {
    hubNetwork: 'hub-vnet-${azureRgSuffix}'
    spokeNetwork: 'spoke-vnet-${azureRgSuffix}'
    azureBastion: 'bastion-${azureRgSuffix}'
    azureBastionPublicIP: 'bastion-ip-${azureRgSuffix}'
    azureFirewall: 'fw-${azureRgSuffix}'
    azureFirewallPublicIP: 'fw-ip-${azureRgSuffix}'
    azureFirewallManagementPublicIP: 'fw-mng-ip-${azureRgSuffix}'
    azureFirewallPolicy: 'fw-policy-${azureRgSuffix}'
    internetRouteTable: 'iroute-${azureRgSuffix}'
    hubPeering: 'hub-peering-${azureRgSuffix}'
    spokePeering: 'spoke-peering-${azureRgSuffix}'
    vpnPublicIP: 'vpn-ip-${azureRgSuffix}'
    vpnGateway: 'vpn-${azureRgSuffix}'
  }
  management: {
    storageAccount: 'sa-${azureRgSuffix}'
    filePrivateEndpoint: 'file-pe-${azureRgSuffix}'
  }
  compute: {
    clusterName: 'spoke-cluster'
  }
}

param networkConfiguration = {
  hubNetwork: {
    addressSpaces: [
      '10.0.0.0/16'
    ]
    subnets: {
      azureFirewallSubnet: '10.0.1.0/26'
      azureFirewallManagementSubnet: '10.0.1.64/26'
      azureBastionSubnet: '10.0.1.128/26'
      azureGatewaySubnet: '10.0.2.0/24'
      azureVMSubnet: '10.0.3.0/24'
      azureDNSSubnet: '10.0.4.0/24'
    }
  }
  spokeNetwork: {
    addressSpaces: [
      '10.10.0.0/16'
    ]
    subnets: {
      azureAKSSubnet: '10.10.1.0/24'
      azureFilesEndpointSubnet: '10.10.2.0/24'
      azureTestSubnet: '10.10.3.0/24'
    }
  }
  staticIPAddresses: {
    azureFirewall: '10.0.1.4'
    hubVM: '10.0.3.4'
    testVM: '10.10.3.4'
    AKSAPIServer: '10.10.1.4'
    AKSNode1: '10.10.1.5'
    AKSLoadBalancer1: '10.10.1.6'
    dnsVM: '10.0.4.4'
  }
}

param virtualMachineGlobals = {
  adminUsername: 'linuxadmin'
  adminPassword: 'Nicholas01!'
  osVersion: 'Ubuntu-2204'
  imageReference: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  vmSize: 'Standard_D2s_v5'
  vmZone: '1'
  sqlEnabled: false 
  backupEnabled: false 
  sqlServerLicense: ''
  osDisk: {
    diskSize: 30
    diskType: 'Standard_LRS'
  }
}

param virtualMachineProperties = {
  hubVm: {
    name: 'hub-vm'
    vmSubnet: 'VMSubnet'
    vmPrivateIPAddress: networkConfiguration.staticIPAddresses.hubVM
  }
  testVm: {
    name: 'test-vm'
    vmSubnet: 'TestSubnet'
    vmPrivateIPAddress: networkConfiguration.staticIPAddresses.testVM
  }
  dnsForwarder: {
    name: 'dns-vm'
    vmSubnet: 'DnsSubnet'
    vmPrivateIPAddress: networkConfiguration.staticIPAddresses.dnsVM
  }
}

param aksConfig = {
  aksVersion: '1.31'
  adminGroupObjectID: ''
  podCidr: '10.10.20.0/24'
  serviceCidr:'10.10.30.0/24'
  dnsServiceIP: '10.10.20.10'
  systemNodePool: {
    vmSize: 'Standard_D2s_v2'
    nodeCount: 2
  }
}
