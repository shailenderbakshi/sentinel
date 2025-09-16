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
@minValue(30) @maxValue(730)
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

// ----------------------------------------------------------------------------
// Workspace (create or reference existing)
// ----------------------------------------------------------------------------
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (createWorkspace) {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    features: { searchVersion: 1 }
    sku: { name: workspaceSku }
  }
}

resource existingLaw 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!createWorkspace) {
  name: workspaceName
}

// Use a single symbol for the workspace (created or existing)
var ws = createWorkspace ? law : existingLaw

// ----------------------------------------------------------------------------
// Enable Microsoft Sentinel (extension resource on the workspace)
// ----------------------------------------------------------------------------
resource onboarding 'Microsoft.SecurityInsights/onboardingStates@2022-11-01-preview' = {
  name: 'default'
  scope: ws
  properties: {}
}

// ----------------------------------------------------------------------------
// Data Connectors (extension resources on the workspace)
// Names must be GUIDs; use deterministic guid() so redeploys are idempotent
// ----------------------------------------------------------------------------
var m365Guid   = guid(subscription().id, resourceGroup().id, workspaceName, 'm365defender')
var o365Guid   = guid(subscription().id, resourceGroup().id, workspaceName, 'office365')
var tiGuid     = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-built-in')
var taxiiGuid  = guid(subscription().id, resourceGroup().id, workspaceName, 'ti-taxii')

// Microsoft 365 Defender
resource m365Defender 'Microsoft
