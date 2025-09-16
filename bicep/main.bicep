// bicep/main.bicep  (RG-scope)

@description('Azure region')
param location string = resourceGroup().location

@description('Log Analytics workspace name')
param workspaceName string = 'law-sentinel-${uniqueString(resourceGroup().id)}'

@description('Retention in days (30–730)')
@minValue(30)
@maxValue(730)
param retentionDays int = 30

@description('Workspace SKU')
@allowed([
  'PerGB2018'
  'PerNode'
  'Free'
  'Standalone'
  'CapacityReservation'
  'LACluster'
])
param workspaceSku string = 'PerGB2018'

@description('Tags to apply to all resources')
param tags object = {
  env: 'dev'
  iac: 'bicep'
}

//
// Log Analytics Workspace
//
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionDays
    features: {
      searchVersion: 1
    }
    sku: {
      name: workspaceSku
    }
  }
}

//
// Enable Microsoft Sentinel on the workspace
//
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${law.name})'
  location: location
  tags: tags
  plan: {
    name: 'SecurityInsights(${law.name})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: law.id
  }
}

output workspaceId string = law.id
output workspaceNameOut string = law.name
output sentinelSolutionName string = sentinel.name
