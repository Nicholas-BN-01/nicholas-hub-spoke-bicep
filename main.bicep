targetScope = 'subscription'

param resourceNames object
param resourceLocation string
param networkConfiguration object
//param virtualMachineGlobals object
//param virtualMachineProperties object
//param aksConfig object
//param storageConfig object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'nicholas-hub-spoke-bicep'
  location: resourceLocation
}

module networkDeploy 'Modules/Network/network-deploy.bicep' = {
  scope: resourceGroup
  name: 'network-deploy'
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    networkConfiguration: networkConfiguration
  }
}

module dnsDeploy 'Modules/Dns/privateDnsZones.bicep' = {
  scope: resourceGroup
  name: 'dns-deploy'
  dependsOn: [
    networkDeploy
  ]
  params: {
    resourceNames: resourceNames
  }
}

module managementDeploy 'Modules/Management/misc-deploy.bicep' = {
  scope: resourceGroup
  name: 'management-deploy'
  dependsOn: [
    networkDeploy
  ]
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    filePrivateDnsZoneID: dnsDeploy.outputs.filePrivateDNSZoneID
  }
}
