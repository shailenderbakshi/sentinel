targetScope = 'resourceGroup'

var location      = 'uksouth'
var workspaceName = 'law-sentinel'

/* Log Analytics Workspace */
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
  }
}

/* (optional) Legacy Sentinel solution – still fine */
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
    promotionCode: ''
  }
}

/* REQUIRED: Onboard workspace to Sentinel (use preview API that supports onboardingState) */
resource sentinelOnboarding 'Microsoft.SecurityInsights/onboardingStates@2022-11-01-preview' = {
  name: 'default'
  scope: workspace
  properties: {
    onboardingState: 'Onboarded'
  }
  dependsOn: [
    workspace
  ]
}

/* Outputs */
output workspaceId   string = workspace.id
output workspaceName string = workspace.name
output sentinelId    string = sentinelSolution.id
