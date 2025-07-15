targetScope = 'subscription'

param resourceNames object
param resourceLocation string
param networkConfiguration object
param virtualMachineGlobals object
param virtualMachineProperties object
//param aksConfig object
//param storageConfig object

var deployNetwork = false
var deployDns = false
var deployMng = false
var deployCompute = true

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'nicholas-hub-spoke-bicep'
  location: resourceLocation
}


module networkDeploy 'Modules/Network/network-deploy.bicep' = if (deployNetwork) {
  scope: resourceGroup
  name: 'network-deploy'
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    networkConfiguration: networkConfiguration
  }
}

module dnsDeploy 'Modules/Dns/privateDnsZones.bicep' = if (deployDns) {
  scope: resourceGroup
  name: 'dns-deploy'
  dependsOn: [
    networkDeploy
  ]
  params: {
    resourceNames: resourceNames
  }
}

module managementDeploy 'Modules/Management/misc-deploy.bicep' = if (deployMng) {
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

module computeDeploy 'Modules/Compute/compute-deploy.bicep' = if (deployCompute) {
  scope: resourceGroup
  name: 'compute-deploy'
  dependsOn: [
    networkDeploy
    managementDeploy
  ]
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    virtualMachineGlobals: virtualMachineGlobals
    virtualMachineProperties: virtualMachineProperties
  }
}
