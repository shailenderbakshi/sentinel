targetScope = 'resourceGroup'

@description('Tenant ID taken directly from deployment context')
param tenantId string = subscription().tenantId

// fixed values, no YAML params required
var location = 'uksouth'
var workspaceName = 'law-sentinel-jorgebernhardt.com'

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
  tags: {
    environment: 'jorgebernhardt.com'
    bicep: 'true'
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
  }
}

// ---------------------------
// Entra ID (AAD) connector
// ---------------------------
resource aadConnector 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = {
  name: guid(workspace.id, 'aad-connector')
  scope: workspace
  kind: 'AAD'
  properties: {
    tenantId: tenantId
    dataTypes: {
      logs: { state: 'Enabled' }
    }
  }
  dependsOn: [ sentinel ]
}

// ---------------------------
// Outputs
// ---------------------------
output workspaceId string = workspace.id
output sentinelId string = sentinel.id
output connectorId string = aadConnector.id
