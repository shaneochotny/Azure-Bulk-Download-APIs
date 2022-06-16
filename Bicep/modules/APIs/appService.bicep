/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs: Azure App Service
//
//        Azure Functions for the APIs.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourceGroupPrefix string
param resourcePrefix string

// Reference: Log Analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${resourcePrefix}monitoring'
  scope: resourceGroup('${resourceGroupPrefix}Monitoring')
}

// Azure Storage: Storage for the App Service
//   Azure: https://docs.microsoft.com/en-us/azure/app-service/operating-system-functionality
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource apiStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${resourcePrefix}apis'
  location: azureRegion
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// Azure App Service: Consumption compute tier for the Function API's
//   Azure: https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms
resource apiAppServicePlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: '${resourcePrefix}apis'
  location: azureRegion
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Azure App Service: Diagnostic Logs
//   Azure: https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource apiAppServicePlanDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: apiAppServicePlan

  properties: {
    workspaceId: logAnalytics.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Azure App Service Site: Functions
//   Azure: https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites
resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: '${resourcePrefix}apis'
  location: azureRegion
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: apiAppServicePlan.id
    clientAffinityEnabled: true
  }
}

// Azure App Service Site: Diagnostic Logs
//   Azure: https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource functionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: functionApp

  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output functionAppOutboundIPAddresses array = split(functionApp.properties.possibleOutboundIpAddresses, ',')
