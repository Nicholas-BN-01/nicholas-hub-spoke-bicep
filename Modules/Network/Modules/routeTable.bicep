param resourceNames object
param resourceLocation string

param azureFirewallPrivateIP string

resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: resourceNames.network.internetRouteTable
  location: resourceLocation
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'Internet'
        type: 'Internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIP
        }
      }
      {
        name: 'VPN-Clients-Return'
        properties: {
          addressPrefix: '172.16.0.0/24'
          nextHopType: 'VirtualNetworkGateway'
        }
      }
    ]
  }
}

resource vmRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'vm-route'
  location: resourceLocation
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'VM-to-AKS'
        properties: {
          addressPrefix: '10.10.1.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIP
        }
      }
      {
        name: 'VM-to-Files'
        properties: {
          addressPrefix: '10.10.2.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIP
        }
      }
    ]
  }
}

output routeTableID string = routeTable.id
output vmRouteTableID string = vmRouteTable.id
