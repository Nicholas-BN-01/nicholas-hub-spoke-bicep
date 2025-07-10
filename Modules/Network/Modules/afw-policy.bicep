param resourceNames object
param resourceLocation string

resource azureFirewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: resourceNames.network.azureFirewallPolicy
  location: resourceLocation
  properties: {
    sku: {
      tier: 'Basic'
    }
    threatIntelMode: 'Alert'
  }
}

output azureFirewallPolicyID string = azureFirewallPolicy.id
