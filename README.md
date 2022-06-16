# Azure Bulk Download APIs

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Bulk-Download-APIs\/main/Images/Azure-Bulk-Download-APIs.gif)

# Description

Azure Storage is a great way to allow for sharing and downloading of large files. This is an example of creating APIs over top of Azure
Storage to extend that capability and add security, authentication, and customer/user delineation. It contains two apis; <b>listFiles</b> 
which will list all the available files, and <b>getFile</b> which will allow the download of the specified file.

<br/>

# How it Works

1. API Management provides authentication for the APIs using Subscription Keys.
2. Calling the <b>listFiles</b> API with the Subscription Key returns a JSON list of available files for download associated with that Subscription Key.
3. The API Management Subscription Key Name (CustomerA) is used to list files in the Azure Storage Container with the same name.
4. Calling the <b>getFile</b> API with the Subscription Key along with the file name will generate an Azure Storage Shared Access Signature.
5. The Azure Storage Shared Access Signature is valid for 20 minutes, valid for only the requested file, and valid for only the calling users IP address.
6. The <b>getFile</b> API then performs a 302 redirect to the Azure Storage account using the generated Shared Access Signature.
7. The requested file is downloaded directly from Azure Storage without passing through the API or API Management.

<br/>

# How to Use

1. Create a new Subscription in API Management.
2. Create a new Container in the Storage Account. The Container name must match the Subscription name exactly.
3. Call the <b>listFiles</b> and <b>getFile</b> APIs and pass the Subscription Key as the 'key' query parameter or within the request header.
   
   ```
   https://myexampleapimanagement.azure-api.net/listFiles?key=5daff3089a024ce2851d4d10c2859446
   ```

<br/>

# How to Deploy


## Environment Deployment
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Bulk-Download-APIs
@Azure:~$ cd Azure-Bulk-Download-APIs
@Azure:~$ code Bicep/main.parameters.json
@Azure:~$ az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Bulk-APIs --location eastus 
```

## API Code Deployment

The API code can be delpoyed directly to the Function App via Visual Studio Code.

<br>

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Bulk-Download-APIs\/main/Images/API-Code-Deployment.gif)

<br/>

# What's Deployed

### <b>Resource Group:</b> {prefix}-APIs
- <b>API Management:</b> Provides authentication for the APIs. 
- <b>Functions App Service:</b> The <b>listFiles</b> and <b>getFile</b> which can only be access from API Management.
- <b>Key Vault:</b> Contains the Storage Account Key used by the APIs to create the Shared Access Signatures.

### <b>Resource Group:</b> {prefix}-Monitoring
- <b>Application Insights:</b> Application-level logging and monitoring for Azure Functions and Azure API Management.
- <b>Log Analytics:</b> Service-level logging and monitoring for all services within the environment.

### <b>Resource Group:</b> {prefix}-Storage
- <b>Azure Storage:</b> Storage account that contains all the downloadable customer data.

<br/>

# Additional Access Controls
The Functions App Service has firewall restrictions enabled to only allow connectivity from API Management but otherwise uses anonymous authentication. You can further restrict access by using Managed Identity for authentication between API Management and the Functions App Service. This will ensure that regardless of firewall rules, only API Management can authenticate and call the APIs.

<br/>

## 1. Enable Authentication on the Function App

1. Goto the Function App located in the <b>{prefix}-APIs</b> Resource Group from within the Azure Portal.
2. Select <b>Authentication</b> from within the <b>Settings</b> menu.
3. Click <b>Add identity provider</b>.
4. Select <b>Microsoft</b>
   1. Select <b>HTTP 401 Unauthorized: recommended for APIs</b>
   2. Uncheck <b>Token store</b>
   3. Click <b>Add</b>
5. Click the account name in parenthesis next to the <b>Microsoft</b> identity provider. This will open the application regsitration.
6. Copy the <b>Application (client) ID</b> GUID (dddddddd-dddd-dddd-dddd-dddddddddddd).
7. Click <b>App roles</b> from within the <b>Manage</b> menu.
8. Click <b>Create app role</b>.
   1. <b>Display name:</b> APIM
   2. <b>Allowed member types:</b> Applications
   3. <b>Value:</b> APIM
   4. <b>Description:</b> Role for API Management access. 
9. Click <b>Apply</b>.
10. Copy the APIM app role <b>ID</b> GUID (bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb).
11. Click <b>Overview</b> from within the menu.
12. Click the <b>Managed application in local directory</b> link in the Essentials menu. This will open the Enterprise Application.
13. Copy the <b>Object ID</b> GUID (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa)
14. Select <b>Properties</b> from within the <b>Manage</b> menu.
15. Click <b>Yes</b> for <b>Assignment required?</b>. By default, any authenticated user within your Azure Active Directory can authenticate and access the Function App. This removes that ability.
16. Click <b>No</b> for <b>Visible for users?</b>.
17. Click <b>Save</b>.

<br/>

## 2. Obtain the API Management Managed Identity Principal ID
1. Goto the API Management resource located in the <b>{prefix}-APIs</b> Resource Group from within the Azure Portal.
2. Select <b>Managed identities</b> from within the <b>Security</b> menu.
3. Copy the <b>Object (principal) ID</b> GUID (cccccccc-cccc-cccc-cccc-cccccccccccc).

<br/>

## 3. Assign the API Management Managed Identity to the Function App Role

Update the below PowerShell command with the previously obtained GUID's. This adds the API Management Managed Identity to the Function App Role we previously created.

- ObjectId: Function App Enterprise Application Object ID (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa)
- ResourceId: Function App Enterprise Application Object ID (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa)
- Id: APIM App Role ID (bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb)
- PrincipalId: API Management Managed Identity Principal ID (cccccccc-cccc-cccc-cccc-cccccccccccc
  
<br>
   
```
New-AzureADServiceAppRoleAssignment -ObjectId aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -ResourceId aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -Id bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb -PrincipalId cccccccc-cccc-cccc-cccc-cccccccccccc
```

<br/>

## 4. Configure the API Management Policy to enable Managed Identity Authentication

1. Goto the API Management resource located in the <b>{prefix}-APIs</b> Resource Group from within the Azure Portal.
2. Select <b>APIs</b> from within the <b>APIs</b> menu.
3. Select the <b>Bulk-APIs</b> API.
4. Within <b>Inbound processing</b>, click <b></></b> to open the policy code editor.
5. Added in the below <b>authentication-managed-identity</b> XML.
6. Update the resource GUID (dddddddd-dddd-dddd-dddd-dddddddddddd) to the Function App Application (client) ID.
7. Click <b>Save</b>.

<br>
   
```

<policies>
    <inbound>
        <authentication-managed-identity resource="dddddddd-dddd-dddd-dddd-dddddddddddd" output-token-variable-name="msi-access-token" ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
        </set-header>
        <base />
        <set-header name="client-id" exists-action="override">
            <value>@(context.Subscription.Name)</value>
        </set-header>
        <set-header name="true-client-ip" exists-action="override">
            <value>@(context.Request.IpAddress)</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

<br>

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Bulk-Download-APIs\/main/Images/Additional-Access-Controls.gif)