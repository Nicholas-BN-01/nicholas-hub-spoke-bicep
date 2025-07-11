param resourceNames object
param resourceLocation string
param filePrivateDNSZoneID string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replace(toLower(substring(resourceNames.management.storageAccount, 0, min(length(resourceNames.management.storageAccount), 24))), '-', '')
  location: resourceLocation
  kind: 'FileStorage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    largeFileSharesState: 'Disabled'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource spokeNetworkExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource privateEndpointSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: spokeNetworkExisting
  name: 'FilesEndpointSubnet'
}

resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: resourceNames.management.filePrivateEndpoint
  location: resourceLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'filePrivateEndpoint'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetExisting.id
    }
  }
}

resource filePrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'filePrivateDNSZoneGroup'
  parent: filePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: filePrivateEndpoint.name
        properties: {
          privateDnsZoneId: filePrivateDNSZoneID
        }
      }
    ]
  }
}
