using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Azure.Storage.Sas;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace BulkAPI.ClientAPIs
{
    public class listFiles
    {
        public class FileList
        { 
            public string file { get; set; }
            public string uri { get; set; }
            public string created { get; set; }
            public string md5 { get; set; }
        }

        [FunctionName("listFiles")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req,
            ILogger _logger)
        {
            // Ensure the Client ID was added in the header by API Management. It's required 
            // because we use this to build the path and restrict access.
            if (!req.Headers.TryGetValue("client-id", out var clientId))
            {
                _logger.LogCritical("client-id header key not set");
                return new UnauthorizedResult();
            }

            try
            {
                // Obtain the list of files associated with the client-id.
                List<FileList> fileList = await getFileList(clientId);
                req.HttpContext.Response.Headers.Add("Content-Type", "application/json");

                // Return our JSON array of files.
                return new OkObjectResult(fileList);
            } 
            catch (Exception) 
            {
                // Some exception occured so return a teapot.
                return new StatusCodeResult(418);
            }
        }

        private async Task<List<FileList>> getFileList(string clientId)
        {
            // Obtain the SAS and full URI at the container-level with only LIST access.
            UriBuilder sasUri = await new Helpers().generateSAS(clientId, IPAddress.None, BlobAccountSasPermissions.List);
            BlobContainerClient blobContainerClient = new BlobContainerClient(sasUri.Uri);

            // getFile API URI prefix. This is used to construct a few URI for each blob.
            string getFileApiUri = System.Environment.GetEnvironmentVariable("getFileApiUri");

            // Iterate through all the blobs using 'clientId' as the container name and create a JSON array. clientId
            // is derived from the 'client-id' HTTP header attribute and can only be set by API Management. This is 
            // how we restrict which clients can list and download which files. We can do this via metadata attributes, 
            // containers for each client, or actual folders by enabling hierarchial namespace on the Storage Account.
            // There isn't necessarily a right or wrong way, so I picked one.
            List<FileList> fileList = new List<FileList>();
            await foreach (BlobItem blob in blobContainerClient.GetBlobsAsync())
            {
                // We return a few pieces of metadata with each blob.
                fileList.Add(new FileList { 
                    file = blob.Name, 
                    uri = getFileApiUri + blob.Name, 
                    created = blob.Properties.CreatedOn?.ToString("yyyy-MM-ddTHH:mm:ssZ"), 
                    md5 = Convert.ToHexString(blob.Properties.ContentHash).ToLower()
                });
            }

            return fileList;
        }
    }
}

