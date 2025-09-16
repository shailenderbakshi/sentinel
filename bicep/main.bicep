targetScope = 'resourceGroup'

@description('Azure region for the workspace')
param location string = resourceGroup().location

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Create the workspace if it does not already exist')
param createWorkspace bool = true

@description('Log Analytics SKU')
@allowed(['PerGB2018','Free','Standalone','CapacityReservation'])
param workspaceSku string = 'PerGB2018'

@description('Retention in days (30–730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Enable Microsoft 365 Defender connector')
param enableM365Defender bool = true

@description('Enable Office 365 connector (ExO/SPO/Teams) – requires tenant admin consent post-deploy')
param enableOffice365 bool = false

@description('Enable built-in Threat Intelligence connector')
param enableThreatIntel bool = true

@description('Enable TAXII connector for external TI feeds')
param enableTaxii bool = false

@description('TAXII settings (used only if enableTaxii = true)')
param taxiiServer string = ''
param taxiiCollectionId string = ''
param taxiiUsername string = ''
@secure()
param taxiiPassword string = ''
param taxiiPollingFrequencyMins int = 60

// 1) Create workspace (optional)
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (createWorkspace) {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    features: { searchVersion: 1 }
    sku: { name: workspaceSku }
  }
}

// 2) Bind an existing symbol (works whether we created it above or it already existed)
resource ws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// 3) Enable Microsoft Sentinel (extension resource)
resource onboarding 'Microsoft.SecurityInsights/onboardingStates@2022-11-01-preview' = {
  name: 'default'
  scope: ws
  properties: {}
}

// Deterministic names for connectors (idempotent)
var m365Guid  = guid(subscription().id, resourceGroup().id, workspaceName, 'm365defender')
var o365Guid  = guid(subscription().id, resourceGroup().id, workspaceName, 'office365')
var tiGuid    = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-built-in')
var taxiiGuid = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-taxii')

// 4) Data Connectors (extension resources on the workspace)
resource m365Defender 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableM365Defender) {
  name: m365Guid
  scope: ws
  kind: 'Microsoft365Defender'
  properties: {
    tenantId: subscription().tenantId
  }
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
}

resource tiBuiltIn 'Microsoft.SecurityInsights/dataConnectors@2022-11-01-preview' = if (enableThreatIntel) {
  name: tiGuid
  scope: ws
  kind: 'ThreatIntelligence'
  properties: {
    dataTypes: {
      Indicators: { state: 'Enabled' }
    }
  }
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
    dataTypes: {
      Indicators: { state: 'Enabled' }
    }
  }
}

output workspaceIdOut string = ws.id
