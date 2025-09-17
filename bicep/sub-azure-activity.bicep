targetScope = 'subscription'

@description('Resource ID of the target Log Analytics workspace')
param lawResourceId string

resource subDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Send-Subscription-Activity-to-LAW'
  scope: subscription()
  properties: {
    workspaceId: lawResourceId
    logs: [
      { category: 'Administrative',  enabled: true }
      { category: 'Security',        enabled: true }
      { category: 'ServiceHealth',   enabled: true }
      { category: 'Alert',           enabled: true }
      { category: 'Recommendation',  enabled: true }
      { category: 'Policy',          enabled: true }
      { category: 'Autoscale',       enabled: true }
      { category: 'ResourceHealth',  enabled: true }
    ]
  }
}
