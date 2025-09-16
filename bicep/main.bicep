targetScope = 'resourceGroup'

@description('Location for resources')
param location string = 'uksouth'

@description('Base name for the workspace')
param baseName string = 'sec-law-uks'

var workspaceName = '${baseName}-law'
var solutionName  = 'SecurityInsights(${workspaceName})'

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

// Connectors as a module (keeps scopes clean and avoids copy/paste typos)
module connectors 'connectors.bicep' = {
  name: 'sentinel-connectors'
  params: {
    workspaceId: law.id
    tenantId: subscription().tenantId
  }
  dependsOn: [ sentinel ]
}
