/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Monitoring: Azure Log Analytics
//
//        Logging and telemetry for all Azure services in the environment.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourcePrefix string

// Azure Log Analytics: Logging and telemetry for all Azure services in the environment
//   Azure: https://docs.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${resourcePrefix}monitoring'
  location: azureRegion
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}
