using System;
using System.Net;
using System.Threading.Tasks;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Storage;
using Azure.Storage.Sas;

namespace BulkAPI.ClientAPIs
{
    public class Helpers
    {
        public async Task<UriBuilder> generateSAS(string clientId, IPAddress clientIPAddress, BlobAccountSasPermissions sasPermissions, string blobName = null)
        {
            // These variables are defined in the Azure Functions Application Settings
            string storageAccountName = System.Environment.GetEnvironmentVariable("storageAccountName");
            string storageAccountFQDN = System.Environment.GetEnvironmentVariable("storageAccountFQDN");
            string storageAccountKey = await getStorageKey();

            // Storage Account container should be lower case.
            string storageContainerName = clientId.ToLower();

            // Create our SAS based on the Storage Account credentials and below options.
            var storageCredential = new StorageSharedKeyCredential(storageAccountName, storageAccountKey);
            var sasOptions = new BlobSasBuilder
            {
                BlobName = string.IsNullOrEmpty(blobName) ? "" : blobName,
                BlobContainerName = storageContainerName,
                StartsOn = DateTime.UtcNow.AddMinutes(-10),
                ExpiresOn = DateTime.UtcNow.AddMinutes(20),
                IPRange = new SasIPRange(clientIPAddress)
            };
            sasOptions.SetPermissions(sasPermissions);

            // Construct a full URI to the blob with the above SAS.
            UriBuilder sasUri = new UriBuilder($"{storageAccountFQDN}/{storageContainerName}/{sasOptions.BlobName}");
            sasUri.Scheme = "https";
            sasUri.Port = 443;
            sasUri.Query = sasOptions.ToSasQueryParameters(storageCredential).ToString();

            return sasUri;
        }

        private async Task<string> getStorageKey()
        {
            // This variable is defined in the Azure Functions Application Settings
            string keyVaultUri = System.Environment.GetEnvironmentVariable("keyVaultUri");

            SecretClientOptions options = new SecretClientOptions()
            {
                Retry =
                {
                    Delay= TimeSpan.FromSeconds(2),
                    MaxDelay = TimeSpan.FromSeconds(16),
                    MaxRetries = 5,
                    Mode = Azure.Core.RetryMode.Exponential
                }
            };

            // Fetch the Storage Account Key from Azure Key Vault
            var client = new SecretClient(new Uri(keyVaultUri), new DefaultAzureCredential(), options);
            KeyVaultSecret secret = await client.GetSecretAsync("Storage");

            return secret.Value;
        }
    }
}

