targetScope = 'resourceGroup'

@description('Location for the Log Analytics workspace and Sentinel solution')
param location string = 'uksouth'

@description('Base name for resources')
param baseName string = 'sec-law-uks'

var workspaceName = '${baseName}-law'
var solutionName  = 'SecurityInsights(${workspaceName})'

// Log Analytics Workspace
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Enable Microsoft Sentinel (solution)
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: solutionName
  location: location
  plan: {
    name: solutionName
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
  }
  properties: {
    workspaceResourceId: law.id
  }
}

// ---------- Sentinel data connectors as typed extension resources ----------

// Entra ID (AAD) connector
resource aadConnector 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = {
  name: guid(law.id, 'aad-connector')
  scope:
