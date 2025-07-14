param resourceNames object
param resourceLocation string

param azureFirewallPolicyId string

resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: resourceNames.network.hubNetwork
}

resource azureFirewallManagementSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'AzureFirewallManagementSubnet'
}

resource azureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnetExisting
  name: 'AzureFirewallSubnet'
}

resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: resourceNames.network.azureFirewallPublicIP
  location: resourceLocation
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Detach'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallManagementPublicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: resourceNames.network.azureFirewallManagementPublicIP
  location: resourceLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Detach'
    publicIPAddressVersion: 'IPv4'
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: resourceNames.network.azureFirewall
  location: resourceLocation
  dependsOn: [
    azureFirewallSubnet
    azureFirewallManagementSubnet
  ]
  properties: {
    sku: {
      tier: 'Basic'
    }
    firewallPolicy: {
      id: azureFirewallPolicyId
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallPublicIP'
        properties: {
          publicIPAddress: {
            id: firewallPublicIP.id
          }
          subnet: {
            id: azureFirewallSubnet.id
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: 'AzureFirewallManagementIP'
      properties: {
        publicIPAddress: {
          id: firewallManagementPublicIP.id
        }
        subnet: {
          id: azureFirewallManagementSubnet.id
        }
      }
    }
  }
}

output azureFirewallID string = azureFirewall.id
