param resourceNames object
param resourceLocation string

param virtualMachineGlobals object
param virtualMachineProperties object

param aksConfig object
param aksPrivateDNSZoneID string
param aadUserObjectID string

var privateDNSZoneContributorID string = 'befefa01-2a29-4197-83a8-272ff33ce314'
var networkContributorID string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var aksClusterUserID string = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

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

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource aksSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: spokeVnetExisting
  name: 'AKSSubnet'
}

// UAMI DNS Zone Contributor

resource uamiDnsZoneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksManagedIdentity.id, resourceGroup().id, 'Private DNS Zone Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${privateDNSZoneContributorID}'
    principalId: aksManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI Network Contributor

resource uamiNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksManagedIdentity.id, aksSubnetExisting.id, 'Network Contributor')
  scope: spokeVnetExisting
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${networkContributorID}'
    principalId: aksManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI AKS Admin

resource uamiAksAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksManagedIdentity.id, aksSubnetExisting.id, 'Network Contributor')
  scope: aksSubnetExisting
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${aksClusterUserID}'
    principalId: aksManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Tenant AKS Admin

resource aksUserRbacRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksManagedIdentity.id, aadUserObjectID, 'AKS Cluster Admin')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${aksClusterUserID}'
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
  dependsOn: [
    uamiDnsZoneContributorRoleAssignment
  ]
}
