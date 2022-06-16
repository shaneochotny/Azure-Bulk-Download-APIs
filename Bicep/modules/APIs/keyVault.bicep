/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs: Azure Key Vault
//
//        Key Vault secrets for the Storage Account key used to create Shared Access Signatures.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourceGroupPrefix string
param resourcePrefix string
param functionAppOutboundIPAddresses array

// Reference to the Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: '${resourcePrefix}storage'
  scope: resourceGroup('${resourceGroupPrefix}Storage')
}

// Reference: Log Analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${resourcePrefix}monitoring'
  scope: resourceGroup('${resourceGroupPrefix}Monitoring')
}

// Azure Key Vault: Secret Store
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/overview
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '${resourcePrefix}apis'
  location: azureRegion

  properties: {
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: [for ipAddress in functionAppOutboundIPAddresses: {
        value: ipAddress
      }]
    }
  }
}

// Azure Key Vault: Secret
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/secrets/about-secrets
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
resource keyVaultStorageSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'Storage'
  parent: keyVault

  properties: {
    attributes: {
      enabled: true
    }
    value: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
  }
}

// Azure Key Vault: Diagnostic Logs
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/monitor-key-vault
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: keyVault

  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalytics.id
  }
}
