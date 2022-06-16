using System;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Azure.Storage.Sas;

namespace BulkAPI.ClientAPIs
{
    public class getFile
    {
        [FunctionName("getFile")]
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

            // Ensure the Client IP Address was added in the header by API Management.
            // We use this to restrict the SAS to the client IP addrses.
            if (!req.Headers.TryGetValue("true-client-ip", out var clientIP))
            {
                _logger.LogCritical("client-ip header key not set");
                return new UnauthorizedResult();
            }
            
            IPAddress clientIPAddress = IPAddress.Parse(clientIP.ToString());
            
            // Ensure a blob file path was passed in the query string. Otherwise we can't create a SAS.
            string path = req.Query["path"];
            if (string.IsNullOrEmpty(path))
            {
                _logger.LogCritical("empty file path");
                return new OkObjectResult("Pass a file path in the query string.");
            }

            try
            {
                // Obtain the SAS and full URI to the requested blob file with only READ access.
                UriBuilder sasUri = await new Helpers().generateSAS(clientId, clientIPAddress, BlobAccountSasPermissions.Read, path);
                string blobUri = sasUri.Uri.ToString();

                // Send a 302 Redirect using the URI we generated.
                return new RedirectResult(blobUri);
            }
            catch (Exception) 
            {
                // Some exception occured so return a teapot.
                return new StatusCodeResult(418);
            }
        }
    }
}

