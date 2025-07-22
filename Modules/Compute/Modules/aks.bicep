param resourceNames object
param resourceLocation string

param aksManagedIdentityID string
param aksConfig object
param aksPrivateDNSZoneID string
param aadUserObjectID string

// UAMI
// Contributor on Resource Group
// Reader & Contributor on Private DNS Zone

// Tenant
// AKS Cluster Admin on cluster
// Contributor on cluster for Azure Portal
// Network Contributor on Resource Group for Ingress

var privateDNSZoneContributorID string = resourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
var networkContributorID string = resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var aksAdminID string = resourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b')
var contributorID string = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var readerString string = resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

//var aksClusterUserID string = '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource aksNodeSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'AKSSubnet'
}

resource uamiExisting 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: resourceNames.compute.aksManagedIdentity
}

resource privateDNSZoneExisting 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.italynorth.azmk8s.io'
}

// UAMI DNS Zone Contributor

resource uamiDnsZoneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, resourceGroup().id, 'Private DNS Zone Contributor')
  scope: privateDNSZoneExisting
  properties: {
    roleDefinitionId: privateDNSZoneContributorID
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI DNS Zone Reader

resource uamiDnsZoneReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, readerString, 'Private DNS Zone Reader')
  scope: privateDNSZoneExisting
  properties: {
    roleDefinitionId: readerString
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// UAMI Network Contributor on Vnet Spoke

resource uamiNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, aksNodeSubnet.id, 'Network Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: networkContributorID
    principalId: uamiExisting.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Tenant AKS Admin on cluster

resource aksUserRbacRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, aksAdminID, 'AKS Cluster Admin')
  scope: azureKubernetesService
  properties: {
    roleDefinitionId: aksAdminID
    principalId: aadUserObjectID
    principalType: 'User'
  }
}

// Tenant Contributor on AKS cluster

resource contributorRbacRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uamiExisting.id, contributorID, 'AKS Contributor')
  scope: azureKubernetesService
  properties: {
    roleDefinitionId: contributorID
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
      '${uamiExisting.id}': {}
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
