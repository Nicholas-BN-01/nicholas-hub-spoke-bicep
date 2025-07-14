param azureFirewallName string
param policyID string
param resourceLocation string

resource firewall 'Microsoft.Network/azureFirewalls@2024-05-01' existing = {
  name: azureFirewallName
}

resource updateFirewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: firewall.name
  location: resourceLocation
  properties: {
    firewallPolicy: {
      id: policyID
    }
  }
}
