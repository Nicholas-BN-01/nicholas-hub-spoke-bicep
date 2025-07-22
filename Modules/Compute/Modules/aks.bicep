param resourceNames object
param resourceLocation string

param aksManagedIdentityID string
param aksConfig object
param aksPrivateDNSZoneID string
param aadUserObjectID string

var privateDNSZoneContributorID string = 'befefa01-2a29-4197-83a8-272ff33ce314'
var networkContributorID string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var aksClusterUserID string = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource aksNodeSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'AKSSubnet'
}

resource uamiExisting 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: resourceNames.compute.uamiExisting
}

// UAMI DNS Zone Contributor

resource uamiDnsZoneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, resourceGroup().id, 'Private DNS Zone Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${privateDNSZoneContributorID}'
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI Network Contributor

resource uamiNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, aksNodeSubnet.id, 'Network Contributor')
  scope: spokeVnetExisting
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${networkContributorID}'
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI AKS Admin

resource uamiAksAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, aksNodeSubnet.id, 'AKS Cluster User')
  scope: azureKubernetesService
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${aksClusterUserID}'
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Tenant AKS Admin

resource aksUserRbacRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, aadUserObjectID, 'AKS Cluster Admin')
  scope: azureKubernetesService
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${aksClusterUserID}'
    principalId: aadUserObjectID
    principalType: 'User'
  }
}


resource azureKubernetesService 'Microsoft.ContainerService/managedClusters@2025-04-01' = {
  name: resourceNames.compute.clusterName
  location: resourceLocation
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksManagedIdentityID}': {}
    }
  }
  properties: {
    kubernetesVersion: aksConfig.aksVersion
    nodeResourceGroup: '${resourceGroup().name}-AKS-NodePools'
    dnsPrefix: resourceNames.compute.clusterName
    agentPoolProfiles: [
      {
        name: 'system'
        availabilityZones: []
        orchestratorVersion: aksConfig.aksVersion
        osSKU: 'AzureLinux'
        osType: 'Linux'
        osDiskType: 'Managed'
        vmSize: aksConfig.systemNodePool.vmSize
        count: aksConfig.systemNodePool.nodeCount
        kubeletDiskType: 'OS'
        enableAutoScaling: false
        scaleDownMode: 'Deallocate'
        mode: 'System'
        nodeTaints: []
        vnetSubnetID: aksNodeSubnet.id
        maxPods: 30
      }
    ]
    disableLocalAccounts: true
    aadProfile: {
      adminGroupObjectIDs: [
        aksConfig.aadUserObjectId
      ]
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: aksPrivateDNSZoneID
    }
    publicNetworkAccess: 'Disabled'
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      podCidr: aksConfig.podCidr
      dnsServiceIP: aksConfig.dnsServiceIP
      serviceCidr: aksConfig.serviceCidr
    }
  }
}

output AKSID string = azureKubernetesService.id
output aksName string = azureKubernetesService.name
