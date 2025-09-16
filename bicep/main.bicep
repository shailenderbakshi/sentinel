targetScope = 'resourceGroup'

var location      = 'uksouth'
var workspaceName = 'law-sentinel'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''   // <- required to be a string, not null
  }
}

output workspaceId string   = workspace.id
output workspaceName string = workspace.name
output sentinelId string    = sentinel.id
output sentinelName string  = sentinel.name
