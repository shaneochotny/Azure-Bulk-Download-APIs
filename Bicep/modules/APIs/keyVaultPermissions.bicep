/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  APIs: Azure Key Vault Permissions
//
//        Permissions for the Azure Functions Managed Identity to read secrets.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param resourcePrefix string

// Reference: Azure Functions
resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: '${resourcePrefix}apis'
}

// Reference: Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: '${resourcePrefix}apis'
}

// Azure Key Vault: Permissions
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies
resource keyVaultPermissions 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [ 
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
