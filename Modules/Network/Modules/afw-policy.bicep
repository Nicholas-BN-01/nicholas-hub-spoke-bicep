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

resource allowNetworkCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: azureFirewallPolicy
  name: 'allowNetworkCollectionGroup'
  properties: {
    priority: 50000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'OutboundAllow'
        priority: 50000
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Allow All'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '172.16.0.0/24'
              '10.10.1.0/24'
              '10.10.2.0/24'
              '10.0.0.0/16'
              '10.10.3.0/24'
            ]
            destinationAddresses: [
              '0.0.0.0/0'
            ]
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'Allow Spoke-VPN-Return'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '10.10.0.0/16'
            ]
            destinationAddresses: [
              '172.16.0.0/24'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

resource denyNetworkCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: azureFirewallPolicy
  name: 'denyNetworkCollectionGroup'
  properties: {
    priority: 60000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Deny'
        }
        name: 'InboundOutboundDeny'
        priority: 60000
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Deny All'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

output azureFirewallPolicyID string = azureFirewallPolicy.id
