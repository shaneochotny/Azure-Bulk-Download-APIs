/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Template for the Bulk Download API
//
//    This template creates all the resources for the Bulk file download APIs.
//
//    Deployment:
//
//        az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Bulk-APIs --location eastus
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope='subscription'

@description('Region to create all the resources in.')
param azureRegion string

@description('Prefix for the Resource Groups.')
param resourceGroupPrefix string

@description('Prefix for the resources.')
param resourcePrefix string

@description('Resource tag for the environment name.')
param environmentTag string

@description('Resource tag for the application name.')
param applicationTag string

@description('Your Internet IP Address to allow access to the Function App Service.')
param yourIPAddress string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Resource Group:
//    Organization for the API Services.
resource apisResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${resourceGroupPrefix}APIs'
  location: azureRegion
  tags: {
    Environment: environmentTag
    Application: applicationTag
    Purpose: 'Customer APIs'
  }
}

// Azure App Service:
//    Azure Functions for the APIs.
module appService 'modules/APIs/appService.bicep' = {
  name: 'appService'
  scope: apisResourceGroup
  params: {
    azureRegion: azureRegion
    resourceGroupPrefix: resourceGroupPrefix
    resourcePrefix: resourcePrefix
  }
}

// Azure API Management:
//    API Management for the Azure Function APIs.
module apiManagement 'modules/APIs/apiManagement.bicep' = {
  name: 'apiManagement'
  scope: apisResourceGroup
  params: {
    azureRegion: azureRegion
    resourceGroupPrefix: resourceGroupPrefix
    resourcePrefix: resourcePrefix
  }

  dependsOn: [
    appService
  ]
}

// Azure Key Vault: Service
//    Key Vault secrets for the Storage Account key used to create Shared Access Signatures.
module keyVault 'modules/APIs/keyVault.bicep' = {
  name: 'keyVault'
  scope: apisResourceGroup
  params: {
    azureRegion: azureRegion
    resourceGroupPrefix: resourceGroupPrefix
    resourcePrefix: resourcePrefix
    functionAppOutboundIPAddresses: appService.outputs.functionAppOutboundIPAddresses
  }
}

// Azure Key Vault: Permissions
//    Permissions for the Azure Functions Managed Identity to read secrets.
module keyVaultPermissions 'modules/APIs/keyVaultPermissions.bicep' = {
  name: 'keyVaultPermissions'
  scope: apisResourceGroup
  params: {
    resourcePrefix: resourcePrefix
  }

  dependsOn: [
    appService
    keyVault
  ]
}

// Azure App Service: Settings
//    Additional settings for the App Service.
module appServiceSettings 'modules/APIs/appServiceSettings.bicep' = {
  name: 'appServiceSettings'
  scope: apisResourceGroup
  params: {
    resourceGroupPrefix: resourceGroupPrefix
    resourcePrefix: resourcePrefix
    yourIPAddress: yourIPAddress
  }

  dependsOn: [
    appService
    keyVault
  ]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Storage
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Resource Group:
//    Organization for Storage.
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${resourceGroupPrefix}Storage'
  location: azureRegion
  tags: {
    Environment: environmentTag
    Application: applicationTag
    Purpose: 'Storage'
  }
}

// Azure Storage:
//    Storage Account for all bulk API data.
module storageAccount 'modules/Storage/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: storageResourceGroup
  params: {
    azureRegion: azureRegion
    resourceGroupPrefix: resourceGroupPrefix
    resourcePrefix: resourcePrefix
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Monitoring
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Resource Group: 
//    Organization for the monitoring services.
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${resourceGroupPrefix}Monitoring'
  location: azureRegion
  tags: {
    Environment: environmentTag
    Application: applicationTag
    Purpose: 'Platform Monitoring Services'
  }
}

// Azure Log Analytics:
//    Logging and telemetry for all Azure services in the environment.
module logAnalytics 'modules/Monitoring/logAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: monitoringResourceGroup
  params: {
    azureRegion: azureRegion
    resourcePrefix: resourcePrefix
  }
}

// Azure Application Insights:
//    Application-level monitoring for Azure Functions and API Management.
module applicationInsights 'modules/Monitoring/applicationInsights.bicep' = {
  name: 'applicationInsights'
  scope: monitoringResourceGroup
  params: {
    azureRegion: azureRegion
    resourcePrefix: resourcePrefix
  }
}
