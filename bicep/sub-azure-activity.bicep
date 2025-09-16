targetScope = 'subscription'
param workspaceId string
param diagName string = 'send-activity-to-law'

resource subDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagName
  scope: subscription()
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'ServiceHealth', enabled: true }
      { category: 'ResourceHealth', enabled: true }
      { category: 'Alert', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'Recommendation', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Autoscale', enabled: true }
      { category: 'ResourceNotifications', enabled: true }
      { category: 'Maintenance', enabled: true }
    ]
  }
}

