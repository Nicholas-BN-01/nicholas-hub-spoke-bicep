param resourceNames object
param resourceLocation string
param networkConfiguration object

module azureFirewallPolicy 'Modules/afw-policy.bicep' = {
  name: 'azureFirewallPolicy-Deploy'
  params: {
    resourceLocation: resourceLocation
    resourceNames: resourceNames
  }
}

module routeTable 'Modules/routeTable.bicep' = {
  name: 'routeTable-Deploy'
  params: {
    azureFirewallPrivateIP: networkConfiguration.staticIPAddresses.azureFirewall
    resourceLocation: resourceLocation
    resourceNames: resourceNames
  }
}

module virtualNetwork 'Modules/virtualNetwork.bicep' = {
  name: 'virtualNetwork-Deploy'
  params: {
    networkConfiguration: networkConfiguration
    resourceLocation: resourceLocation
    resourceNames: resourceNames
    routeTableID: routeTable.outputs.routeTableID
    gatewayRouteTableID: routeTable.outputs.gatewayRouteTableID
    vmRouteTableID: routeTable.outputs.vmRouteTableID
  }
}

module virtualNetworkPeerings 'Modules/vnet-peering.bicep' = {
  name: 'virtualNetworkPeerings-Deploy'
  params: {
    resourceNames: resourceNames
    hubVnetID: virtualNetwork.outputs.hubVnetID
    spokeVnetID: virtualNetwork.outputs.spokeVnetID
    hubVnetName: virtualNetwork.outputs.hubVnetName
    spokeVnetName: virtualNetwork.outputs.spokeVnetName
  }
}

module azureBastionDeploy 'Modules/bastion.bicep' = {
  dependsOn: [
    virtualNetwork
  ]
  name: 'azureBastion-Deploy'
  params: {
    resourceLocation: resourceLocation
    resourceNames: resourceNames
  }
}

module azureFirewallDeploy 'Modules/afw.bicep' = {
  name: 'azureFirewall-Deploy'
  dependsOn: [
    virtualNetwork
    routeTable
  ]
  params: {
    azureFirewallPolicyId: azureFirewallPolicy.outputs.azureFirewallPolicyID
    resourceLocation: resourceLocation
    resourceNames: resourceNames
  }
}
/*
module azureVPNGatewayDeploy 'Modules/vpnGw.bicep' = {
  name: 'azureVPNGateway-Deploy'
  params: {
    resourceLocation: resourceLocation
    vNetId: virtualNetwork.outputs.hubVnetID
  }
}
*/
