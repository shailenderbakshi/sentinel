targetScope = 'resourceGroup'

param location string = resourceGroup().location
param workspaceName string
param createWorkspace bool = true
@allowed(['PerGB2018','Free','Standalone','CapacityReservation'])
param workspaceSku string = 'PerGB2018'
@minValue(30) @maxValue(730)
param retentionInDays int = 90

param enableM365Defender bool = true
param enableOffice365 bool = false
param enableThreatIntel bool = true
param enableTaxii bool = false

param taxiiServer string = ''
param taxiiCollectionId string = ''
param taxiiUsername string = ''
@secure() param taxiiPassword string = ''
param taxiiPollingFrequencyMins int = 60

// 1) Create LAW (optional)
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (createWorkspace) {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    features: { searchVersion: 1 }
    sku: { name: workspaceSku }
  }
}

// 2) Always bind an existing symbol for the workspace
resource ws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// 3) Enable Microsoft Sentinel (extension resource) — ensure LAW exists first
resource onboarding 'Microsoft.SecurityInsights/onboardingStates@2022-11-01-preview' = {
  name: 'default'
  scope: ws
  properties: {}
  dependsOn: createWorkspace ? [ law ] : []
}

// Deterministic names for connectors
var m365Guid  = guid(subscription().id, resourceGroup().id, workspaceName, 'm365defender')
var o365Guid  = guid(subscription().id, resourceGroup().id, workspaceName, 'office365')
var tiGuid    = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-built-in')
var taxiiGuid = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-taxii')

// 4) Data connectors — also depend on LAW creation when applicable

resource m365Defender 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableM365Defender) {
  name: m365Guid
  scope: ws
  kind: 'Microsoft365Defender'
  properties: {
    tenantId: subscription().tenantId
  }
  dependsOn: createWorkspace ? [ law ] : []
}

resource o365 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableOffice365) {
  name: o365Guid
  scope: ws
  kind: 'Office365'
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      Exchange:   { state: 'Enabled' }
      SharePoint: { state: 'Enabled' }
      Teams:      { state: 'Enabled' }
    }
  }
  dependsOn: createWorkspace ? [ law ] : []
}

resource tiBuiltIn 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableThreatIntel) {
  name: tiGuid
  scope: ws
  kind: 'ThreatIntelligence'
  properties: {
    // dataTypes block is optional; leave minimal to avoid schema warnings
  }
  dependsOn: createWorkspace ? [ law ] : []
}

resource tiTaxii 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableTaxii) {
  name: taxiiGuid
  scope: ws
  kind: 'ThreatIntelligenceTaxii'
  properties: {
    taxiiServer:      taxiiServer
    collectionId:     taxiiCollectionId
    userName:         taxiiUsername
    password:         taxiiPassword
    pollingFrequency: '${taxiiPollingFrequencyMins} Minutes'
    // dataTypes optional
  }
  dependsOn: createWorkspace ? [ law ] : []
}

output workspaceIdOut string = ws.id
