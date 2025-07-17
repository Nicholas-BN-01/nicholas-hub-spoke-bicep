param resourceNames object
param resourceLocation string

param virtualMachineGlobals object
param virtualMachineProperties object

param aksConfig object
param aksPrivateDNSZoneID string
param aadUserObjectID string

var privateDnsZoneContributorRoleGuid = 'e4fe9e66-94ec-4e3e-8c5b-77e2e38e30f7'

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

resource aksPrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.${resourceLocation}.azmk8s.io'
  scope: resourceGroup()
}

resource uamiDnsZoneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksManagedIdentity.id, aksPrivateDNSZoneID, 'Private DNS Zone Contributor')
  scope: aksPrivateDNSZone
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: aksManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aksRbacAdminRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  scope: resourceGroup()
  name: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
}

resource aksUserRbacRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksRbacAdminRoleDefinition.id, aadUserObjectID, aksRbacAdminRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: aksRbacAdminRoleDefinition.id
    principalId: aadUserObjectID
    principalType: 'User'
  }
}

module aksDeploy 'Modules/aks.bicep' = {
  name: 'aks-Deploy'
  params: {
    resourceLocation: resourceLocation
    resourceNames: resourceNames
    aksConfig: aksConfig
    aksManagedIdentityID: aksManagedIdentity.id
    aksPrivateDNSZoneID: aksPrivateDNSZoneID
  }
}
