@description('Azure region for the workspace')
param location string = resourceGroup().location

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Create the workspace if it does not already exist')
param createWorkspace bool = true

@description('Log Analytics SKU')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'CapacityReservation'
])
param workspaceSku string = 'PerGB2018'

@description('Retention in days (30–730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Enable Microsoft 365 Defender connector')
param enableM365Defender bool = true


