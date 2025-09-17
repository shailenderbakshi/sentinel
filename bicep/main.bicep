targetScope = 'resourceGroup'

var location         = 'uksouth'
var workspaceName    = 'law-sentinel'
var retentionInDays  = 90

// --- Log Analytics Workspace ---
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: retentionInDays
  }
}

// --- Sentinel (solution) ---
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
    promotionCode: ''
  }
}

// --- Onboard Sentinel (preview API; no properties payload) ---
resource onboardingStates 'Microsoft.SecurityInsights/onboardingStates@2022-12-01-preview' = {
  name: 'default'
  scope: workspace
}

// --- Outputs (for the sub-scope Azure Activity step) ---
output workspaceId   string = workspace.id
output workspaceName string = workspace.name
output sentinelId    string = sentinel.id
