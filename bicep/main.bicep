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

var workspaceId = createWorkspace ? law.id : existingLaw.id

// ----------------------------------------------------------------------------
// Enable Microsoft Sentinel on the workspace
// ----------------------------------------------------------------------------
resource sentinelOnboarding 'Microsoft.OperationalInsights/workspaces/providers/onboardingStates@2022-11-01-preview' = {
  name: '${workspaceName}/Microsoft.SecurityInsights/default'
  scope: resourceId('Microsoft.OperationalInsights/workspaces', workspaceName)
  properties: {}
}

// ----------------------------------------------------------------------------
/* Data Connectors (workspace scope) */
// ----------------------------------------------------------------------------

// Microsoft 365 Defender
resource m365DefenderConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2023-02-01-preview' = if (enableM365Defender) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${newGuid()}'
  kind: 'Microsoft365Defender'
  scope: resourceId('Microsoft.OperationalInsights/workspaces', workspaceName)
  properties: {
    tenantId: subscription().tenantId
  }
}

// Office 365 (Exchange/SharePoint/Teams)
resource office365Connector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2023-02-01-preview' = if (enableOffice365) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${newGuid()}'
  kind: 'Office365'
  scope: resourceId('Microsoft.OperationalInsights/workspaces', workspaceName)
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      Exchange:   { state: 'Enabled' }
      SharePoint: { state: 'Enabled' }
      Teams:      { state: 'Enabled' }
    }
  }
}

// Threat Intelligence (built-in)
resource tiConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2023-02-01-preview' = if (enableThreatIntel) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${newGuid()}'
  kind: 'ThreatIntelligence'
  scope: resourceId('Microsoft.OperationalInsights/workspaces', workspaceName)
  properties: {
    dataTypes: { Indicators: { state: 'Enabled' } }
  }
}

// Threat Intelligence (TAXII)
resource taxiiConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2023-02-01-preview' = if (enableTaxii) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${newGuid()}'
  kind: 'ThreatIntelligenceTaxii'
  scope: resourceId('Microsoft.OperationalInsights/workspaces', workspaceName)
  properties: {
    taxiiServer:      taxiiServer
    collectionId:     taxiiCollectionId
    userName:         taxiiUsername
    password:         taxiiPassword
    pollingFrequency: '${taxiiPollingFrequencyMins} Minutes'
    dataTypes: { Indicators: { state: 'Enabled' } }
  }
}

// Output workspace resourceId for downstream sub/tenant deployments
output workspaceIdOut string = workspaceId
