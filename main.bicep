targetScope = 'subscription'

param resourceNames object
param resourceLocation string
param networkConfiguration object
//param virtualMachineGlobals object
//param virtualMachineProperties object
//param aksConfig object
//param storageConfig object

var deployNetwork = false
var deployDns = false
var deployMng = true

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (deployNetwork) {
  name: 'nicholas-hub-spoke-bicep'
  location: resourceLocation
}


module networkDeploy 'Modules/Network/network-deploy.bicep' = if (deployDns) {
  scope: resourceGroup
  name: 'network-deploy'
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    networkConfiguration: networkConfiguration
  }
}

module dnsDeploy 'Modules/Dns/privateDnsZones.bicep' = if (deployMng) {
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
