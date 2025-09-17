targetScope = 'resourceGroup'

/* ---- settings ---- */
var location      = 'uksouth'
var workspaceName = 'law-sentinel'

/* ---- Log Analytics Workspace ---- */
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

/* ---- (optional but fine) Sentinel solution resource ---- */
resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
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

/* ---- REQUIRED: Onboard workspace to Sentinel (new API) ---- */
resource sentinelOnboarding 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  name: 'default'
  scope: workspace             // extension resource on the LAW
  properties: {
    onboardingState: 'Onboarded'
  }
}

/* ---- Outputs (used by the workflow for the sub step) ---- */
output workspaceId   string = workspace.id
output workspaceName string = workspace.name
output sentinelId    string = sentinelSolution.id
