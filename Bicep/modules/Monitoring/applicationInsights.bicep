/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Monitoring: Azure Application Insights
//
//        Application-level monitoring for Azure Functions and API Management.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourcePrefix string

// Reference: Log Analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${resourcePrefix}monitoring'
}

// Azure Application Insights: Application-level monitoring for Azure Functions and API Management.
//   Azure: https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcePrefix}monitoring'
  location: azureRegion
  kind: 'other'
  properties: {
    Application_Type: 'other'
    Flow_Type: 'Bluefield'
    IngestionMode: 'LogAnalytics'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics.id
  }
}
