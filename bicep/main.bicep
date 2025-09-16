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
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Microsoft Sentinel enablement (Solution)
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

// ---------------------------
// Sentinel Data Connectors
// ---------------------------

// Entra ID (Azure AD) connector
resource aadConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-11-01-preview' = {
  name: '${law.name}/Microsoft.SecurityInsights/AADConnector'
  kind: 'AAD'
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      logs: {
        state: 'Enabled'
      }
    }
  }
  dependsOn: [ sentinel ]
}

// Microsoft 365 (Office 365) connector – Exchange/SharePoint/Teams
resource o365Connector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-11-01-preview' = {
  name: '${law.name}/Microsoft.SecurityInsights/O365Connector'
  kind: 'Office365'
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      SharePoint: { state: 'Enabled' }
      Exchange:  { state: 'Enabled' }
      Teams:     { state: 'Enabled' }
    }
  }
  dependsOn: [ sentinel ]
}

// Microsoft Defender XDR (MTP) connector
resource mdxdrConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-11-01-preview' = {
  name: '${law.name}/Microsoft.SecurityInsights/MTPConnector'
  kind: 'MicrosoftThreatProtection'
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      Alerts: { state: 'Enabled' }
    }
  }
  dependsOn: [ sentinel ]
}

// (Optional) Example: enable SecurityAlerts table via LA solution packs if needed
// You can add more connectors later (e.g., AzureActivity via diag settings at sub-scope)
