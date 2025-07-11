param resourceNames object
param resourceLocation string

param virtualMachineGlobals object
param virtualMachineProperties object

module virtualMachinesDeploy 'Modules/virtualMachine.bicep' = [
  for virtualMachine in items(virtualMachineProperties): {
    name: '${virtualMachineProperties[virtualMachine.key].name}-Deploy'
    params: {
      location: resourceLocation
      resourceNames: resourceNames
      vmName: virtualMachineProperties[virtualMachine.key].name
      vmSize: virtualMachineGlobals.vmSize
      vmZone: virtualMachineGlobals.vmZone
      adminUsername: virtualMachineGlobals.adminUsername
      adminPassword: virtualMachineGlobals.adminPassword
      osVersion: virtualMachineGlobals.osVersion
      osDiskSize: virtualMachineGlobals.osDisk.diskSize
      osDiskType: virtualMachineGlobals.osDisk.diskType
      subnetName: virtualMachineProperties[virtualMachine.key].vmSubnet
      vmPrivateIPAddress: virtualMachineProperties[virtualMachine.key].vmPrivateIPAddress
      backupEnabled: virtualMachineGlobals.backupEnabled
      sqlEnabled: virtualMachineGlobals.sqlEnabled
      sqlServerLicense: virtualMachineGlobals.sqlServerLicense
    }
  }
]
