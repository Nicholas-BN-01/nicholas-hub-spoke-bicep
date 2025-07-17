param resourceNames object
param resourceLocation string

param aksManagedIdentityID string
param aksConfig object
param aksPrivateDNSZoneID string

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource aksNodeSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeVnetExisting
  name: 'AKSSubnet'
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
        aksConfig.adminGroupObjectID
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
