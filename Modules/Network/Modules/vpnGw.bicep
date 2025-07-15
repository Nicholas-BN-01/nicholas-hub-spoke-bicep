param resourceNames object
param resourceLocation string

param tenantID string = tenant().tenantId

resource hubNetworkExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource vpnSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubNetworkExisting
  name: 'GatewaySubnet'
}

resource vpnPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: resourceNames.network.vpnPublicIP
  location: resourceLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: resourceNames.network.vpnGateway
  location: resourceLocation
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnSubnetExisting.id
          }
          publicIPAddress: {
            id: vpnPublicIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    customRoutes: {
      addressPrefixes: [
        '10.0.0.0/16'
        '10.10.0.0/16'
      ]
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          '172.16.0.0/24'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      #disable-next-line no-hardcoded-env-urls
      aadTenant: 'https://login.microsoftonline.com/${tenantID}/'
      aadAudience: 'c632b3df-fb67-4d84-bdcf-b95ad541b5c8'
      aadIssuer: 'https://sts.windows.net/${tenantID}/'
    }
  }
}
