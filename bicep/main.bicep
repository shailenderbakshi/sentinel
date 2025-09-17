targetScope = 'resourceGroup'

var location      = 'uksouth'
var workspaceName = 'law-sentinel'

// ---------------------------
// Log Analytics Workspace
// ---------------------------
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

// ---------------------------
// Enable Microsoft Sentinel
// ---------------------------
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
    promotionCode: '' // must be a string, cannot be null
  }
}

// ---------------------------
// Outputs (used by workflow)
// ---------------------------
output workspaceId string   = workspace.id
output workspaceName string = workspace.name
output sentinelId string    = sentinel.id
