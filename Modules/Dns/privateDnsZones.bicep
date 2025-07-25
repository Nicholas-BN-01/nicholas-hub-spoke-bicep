param resourceNames object
param resourceLocation string
param networkConfiguration object

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource spokeVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.spokeNetwork
}

resource filePrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  #disable-next-line no-hardcoded-env-urls
  name: 'privatelink.file.core.windows.net'
  location: 'Global'
}

resource filePrivateDNSZoneLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'filePrivateDNSZoneLinkHub'
  parent: filePrivateDNSZone
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: hubVnetExisting.id
    }
    registrationEnabled: false
  }
}

resource filePrivateDNSZoneLinkSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'filePrivateDNSZoneLinkSpoke'
  parent: filePrivateDNSZone
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: spokeVnetExisting.id
    }
    registrationEnabled: false
  }
}

resource internalDNSZoneGroup 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  #disable-next-line no-hardcoded-env-urls
  name: 'nicholas.internal'
  location: 'Global'
}

resource internalDNSZoneLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'internalPrivateDNSZoneLinkHubVnet'
  parent: internalDNSZoneGroup
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: hubVnetExisting.id
    }
    registrationEnabled: true
  }
}

resource internalDNSZoneLinkSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'internalPrivateDNSZoneLinkSpokeVnet'
  parent: internalDNSZoneGroup
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: spokeVnetExisting.id
    }
    registrationEnabled: true
  }
}

resource ingressARecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: internalDNSZoneGroup
  name: 'vamosali'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: networkConfiguration.spokeNetwork.staticIPAddresses.AKSLoadBalancer1
      }
    ]
  }
}

resource aksPrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${resourceLocation}.azmk8s.io'
  location: 'Global'
}

resource aksPrivateDNSZoneLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'aksPrivateDNSZoneLinkHub'
  parent: aksPrivateDNSZone
  dependsOn: [
    filePrivateDNSZone
    filePrivateDNSZoneLinkHub
    filePrivateDNSZoneLinkSpoke
  ]
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: hubVnetExisting.id
    }
    registrationEnabled: false
  }
}

resource aksPrivateDNSZoneLinkSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'aksPrivateDNSZoneLinkSpoke'
  parent: aksPrivateDNSZone
  dependsOn: [
    filePrivateDNSZone
    filePrivateDNSZoneLinkHub
    filePrivateDNSZoneLinkSpoke
  ]
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: spokeVnetExisting.id
    }
    registrationEnabled: false
  }
}

output filePrivateDNSZoneID string = filePrivateDNSZone.id
output aksPrivateDNSZoneID string = aksPrivateDNSZone.id
