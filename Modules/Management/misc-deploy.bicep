param resourceNames object
param resourceLocation string

param filePrivateDnsZoneID string
param storageConfig object

module filesStorage 'Modules/fileStorage.bicep' = {
  params: {
    resourceNames: resourceNames
    resourceLocation: resourceLocation
  }
}
