param resourceNames object
param resourceLocation string

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

output filePrivateDNSZoneID string = filePrivateDNSZone.id
