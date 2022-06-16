/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs: Azure App Service Settings
//
//        Additional settings for the App Service.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param resourceGroupPrefix string
param resourcePrefix string
param yourIPAddress string

// Reference: API Management
resource apiManagement 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: '${resourcePrefix}apis'
}

// Reference: App Service Storage Account
resource apiStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: '${resourcePrefix}apis'
}

// Reference: Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourcePrefix}monitoring'
  scope: resourceGroup('${resourceGroupPrefix}Monitoring')
}

// Reference: App Service Function
resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: '${resourcePrefix}apis'
}

// Reference: Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: '${resourcePrefix}apis'
}

// Azure App Service Site Config: Application Settings
//   Azure: https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-appsettings
resource appServiceSettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${apiStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(apiStorageAccount.id, apiStorageAccount.apiVersion).keys[0].value}'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${apiStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(apiStorageAccount.id, apiStorageAccount.apiVersion).keys[0].value}'
    WEBSITE_CONTENTSHARE: apiStorageAccount.name
    WEBSITE_RUN_FROM_PACKAGE: '1'
    keyVaultUri: keyVault.properties.vaultUri
    storageAccountName: '${resourcePrefix}storage'
    storageAccountFQDN: '${resourcePrefix}storage.blob.${environment().suffixes.storage}'
    getFileApiUri: 'https://${apiManagement.name}.azure-api.net/getFile?path='
  }
}

// Azure App Service Site Config: Firewall Settings
//   Azure: https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites
resource appServiceFirewall 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: functionApp
  name: 'web'

  properties: {
    ipSecurityRestrictions: [
      {
        action: 'Allow'
        description: 'Azure API Management'
        ipAddress: '${apiManagement.properties.publicIPAddresses[0]}/32'
        name: 'APIM'
        priority: 1
      }
      {
        action: 'Allow'
        description: 'Your IP Address'
        ipAddress: '${yourIPAddress}/32'
        name: 'yourIPAddress'
        priority: 2
      }
    ]
    scmIpSecurityRestrictionsUseMain: true
  }
}
