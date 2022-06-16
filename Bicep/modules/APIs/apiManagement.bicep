/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs: API Management
//
//        API Management for the Azure Function APIs.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourceGroupPrefix string
param resourcePrefix string

// Reference: Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourcePrefix}monitoring'
  scope: resourceGroup('${resourceGroupPrefix}Monitoring')
}

// Reference: Azure Functions App Service
resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: '${resourcePrefix}apis'
}

// Reference: Log Analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${resourcePrefix}monitoring'
  scope: resourceGroup('${resourceGroupPrefix}Monitoring')
}

// Azure API Management: Service
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/get-started-create-service-instance
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service
resource apiManagement 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: '${resourcePrefix}apis'
  location: azureRegion

  sku: {
    capacity: 1
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: 'BofA'
    publisherEmail: 'sochotny@microsoft.com'
  }
}

// Azure API Management: Product
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-add-products
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/products
resource apiManagementProduct 'Microsoft.ApiManagement/service/products@2021-12-01-preview' = {
  name: 'Bulk-APIs'
  parent: apiManagement
  properties: {
    approvalRequired: false
    description: 'Bulk download APIs'
    displayName: 'Bulk APIs'
    state: 'published'
    subscriptionRequired: true
  }
}

// Azure API Management: API Product
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/add-api-manually
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/products/apis
resource apiManagementProductAPI 'Microsoft.ApiManagement/service/products/apis@2021-12-01-preview' = {
  name: apiManagementProduct.name
  parent: apiManagementProduct

  dependsOn: [
    appServiceAPI
    appServiceBackend
  ]
}

// Azure API Management: Subscription
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/api-management-subscriptions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/subscriptions
resource apiManagementSubscription 'Microsoft.ApiManagement/service/subscriptions@2021-12-01-preview' = {
  name: 'CustomerA'
  parent: apiManagement
  properties: {
    allowTracing: true
    displayName: 'CustomerA'
    scope: apiManagementProduct.id
    state: 'active'
  }
}

// Azure API Management: API Backend
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/backends
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/backends
resource appServiceBackend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: apiManagementProduct.name
  parent: apiManagement

  properties: {
    description: 'Azure Function APIs'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${functionApp.id}'
    url: 'https://${functionApp.properties.defaultHostName}/api'
  }
}

// Azure API Management: API
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/add-api-manually
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis
resource appServiceAPI 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: apiManagementProduct.name
  parent: apiManagement
  properties: {
    apiRevision: '1'
    apiRevisionDescription: 'Azure Function APIs'
    description: 'Azure Function APIs'
    displayName: apiManagementProduct.name
    isCurrent: true
    path: ''
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'key'
      query: 'key'
    }
    subscriptionRequired: true
  }
}

// Azure API Management: API Policy
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/set-edit-policies
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis/policies
resource appServiceAPIPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: appServiceAPI
  properties: {
    format: 'xml'
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-header name="client-id" exists-action="override">\r\n      <value>@(context.Subscription.Name)</value>\r\n    </set-header>\r\n    <set-header name="true-client-ip" exists-action="override">\r\n      <value>@(context.Request.IpAddress)</value>\r\n    </set-header>\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
  }
}

// Azure API Management: API Operation
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/add-api-manually
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis/operations
resource getFileOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-getfile'
  parent: appServiceAPI
  properties: {
    displayName: 'getFile'
    method: 'GET'
    urlTemplate: '/getFile'
  }
}

// Azure API Management: API Operation Policy
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/set-edit-policies
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis/operations/policies
resource getFileOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: getFileOperation
  properties: {
    format: 'xml'
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service id="apim-generated-policy" backend-id="${apiManagementProduct.name}" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
  }

  dependsOn: [
    appServiceBackend
  ]
}

// Azure API Management: API Operation
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/add-api-manually
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis/operations
resource listFilesOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'get-listfiles'
  parent: appServiceAPI
  properties: {
    displayName: 'listFiles'
    method: 'GET'
    urlTemplate: '/listFiles'
  }
}

// Azure API Management: API Operation Policy
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/set-edit-policies
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/apis/operations/policies
resource listFilesOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: listFilesOperation
  properties: {
    format: 'xml'
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service id="apim-generated-policy" backend-id="${apiManagementProduct.name}" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
  }

  dependsOn: [
    appServiceBackend
  ]
}

// Azure API Management: Diagnostic Logs
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/howto-use-analytics
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource apiManagementDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: apiManagement
  properties: {
    workspaceId: logAnalytics.id
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
  }
}

// Azure API Management: Application Insights Instrumentation Key
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-properties
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/namedvalues
resource apiManagementApplicationInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  name: 'applicationInsights'
  parent: apiManagement
  properties: {
    displayName: 'applicationInsights'
    secret: true
    value: applicationInsights.properties.InstrumentationKey
  }
}

// Azure API Management: Application Insights Logger
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/loggers
resource apiManagementApplicationInsights 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = {
  name: applicationInsights.name
  parent: apiManagement
  properties: {
    credentials: {
      'instrumentationKey': '{{applicationInsights}}'
    }
    isBuffered: true
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
  }

  dependsOn: [
    apiManagementApplicationInsightsKey
  ]
}

// Azure API Management: Application Insights Logs
//   Azure: https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service/diagnostics
resource appServiceAPIApplicationInsights 'Microsoft.ApiManagement/service/diagnostics@2021-12-01-preview' = {
  name: 'applicationinsights'
  parent: apiManagement
  properties: {
    alwaysLog: 'allErrors'
    backend: {
      request: {
        body: {
          bytes: 8192
        }
        headers: []
      }
      response: {
        body: {
          bytes: 8192
        }
        headers: []
      }
    }
    frontend: {
      request: {
        body: {
          bytes: 8192
        }
        headers: []
      }
      response: {
        body: {
          bytes: 8192
        }
        headers: []
      }
    }
    httpCorrelationProtocol: 'Legacy'
    logClientIp: true
    loggerId: apiManagementApplicationInsights.id
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    verbosity: 'information'
  }
}
