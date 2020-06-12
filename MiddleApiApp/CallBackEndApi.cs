using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http;

namespace Jaypaddy.CallBackEnd
{
    public static class CallBackEndApi
    {
        [FunctionName("CallBackEndApi")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string name = req.Query["name"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;
                
            string bearerToken = "NULL";
            string url = System.Environment.GetEnvironmentVariable("BACKENDAPI_URL");
            url = url + "?name=" + name;
            string responseMessage = await TriggerJob(bearerToken,url);
            string clientIP =  req.Headers["X-Forwarded-For"];
            responseMessage = $"MiddleApiApp: Client: {clientIP}" + " called me. And the response back from BackendAPI is:\n" + responseMessage;
            return new OkObjectResult(responseMessage);
        }
        public static async Task<string> TriggerJob(string bearerToken, string url)
        {
            System.Net.Http.HttpResponseMessage response;
            HttpClient hClient = new HttpClient();
            
            HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, url );
            //request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", bearerToken);
            response = await hClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();
            return content;
        }
    }


}
