/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Storage: Storage Account
//
//           Storage Account for all bulk API data.
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

// Azure Storage: Storage for all data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-overview
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${resourcePrefix}storage'
  location: azureRegion
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '00.00:30:00'
    }
  }
}

// Azure Storage: Reference to the Storage Account Blob we created
resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

// Azure Storage: Blob Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/monitor-blob-storage
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource storageAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: storageAccountBlob
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// Azure Storage: Storage Container for CustomerA Example
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource storageDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/customera'
}
