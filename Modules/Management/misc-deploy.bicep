param resourceNames object
param resourceLocation string

param filePrivateDnsZoneID string

module filesStorage 'Modules/fileStorage.bicep' = {
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
    filePrivateDNSZoneID: filePrivateDnsZoneID
  }
}
