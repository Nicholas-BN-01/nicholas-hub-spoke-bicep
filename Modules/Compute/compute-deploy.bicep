param resourceNames object
param resourceLocation string

param virtualMachineGlobals object
param virtualMachineProperties object

param aksConfig object
param aksPrivateDNSZoneID string
param aadUserObjectID string

module virtualMachinesDeploy 'Modules/virtualMachine.bicep' = [
  for virtualMachine in items(virtualMachineProperties): {
    name: '${virtualMachineProperties[virtualMachine.key].name}-Deploy'
    params: {
      resourceNames: resourceNames
      resourceLocation: resourceLocation
      vmName: virtualMachineProperties[virtualMachine.key].name
      vmSize: virtualMachineGlobals.vmSize
      vmZone: virtualMachineGlobals.vmZone
      adminUsername: virtualMachineGlobals.adminUsername
      adminPassword: virtualMachineGlobals.adminPassword
      osVersion: virtualMachineGlobals.osVersion
      osDiskSize: virtualMachineGlobals.osDisk.diskSize
      osDiskType: virtualMachineGlobals.osDisk.diskType
      vmPrivateIPAddress: virtualMachineProperties[virtualMachine.key].vmPrivateIPAddress
      backupEnabled: virtualMachineGlobals.backupEnabled
      sqlEnabled: virtualMachineGlobals.sqlEnabled
      sqlServerLicense: virtualMachineGlobals.sqlServerLicense
    }
  }
]

resource aksManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: resourceNames.compute.aksManagedIdentity
  location: resourceLocation
}

module aksDeploy 'Modules/aks.bicep' = {
  name: 'aks-Deploy'
  params: {
    resourceLocation: resourceLocation
    resourceNames: resourceNames
    aksConfig: aksConfig
    aksManagedIdentityID: aksManagedIdentity.id
    aksPrivateDNSZoneID: aksPrivateDNSZoneID
    aadUserObjectID: aadUserObjectID
  }
}
