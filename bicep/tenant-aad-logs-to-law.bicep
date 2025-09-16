targetScope = 'tenant'
param workspaceId string
param diagName string = 'entra-to-law'

resource aadDiag 'microsoft.aadiam/diagnosticSettings@2020-01-01-preview' = {
  name: diagName
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'SignInLogs', enabled: true }
      { category: 'AuditLogs', enabled: true }
      { category: 'AADNonInteractiveUserSignInLogs', enabled: true }
      { category: 'AADServicePrincipalSignInLogs', enabled: true }
      { category: 'AADManagedIdentitySignInLogs', enabled: true }
      { category: 'AADProvisioningLogs', enabled: true }
      { category: 'ADFSSignInLogs', enabled: false }
      { category: 'AADUserRiskEvents', enabled: true }
      { category: 'AADRiskyUsers', enabled: true }
      { category: 'NetworkAccessTraffic', enabled: true }
      { category: 'AADRiskyServicePrincipals', enabled: true }
      { category: 'AADServicePrincipalRiskEvents', enabled: true }
    ]
  }
}

