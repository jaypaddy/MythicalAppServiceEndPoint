using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Jaypaddy.BackendApi
{
    public static class BackendAPI
    {
        [FunctionName("BackendAPI")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string name = req.Query["name"];
            string clientIP =  req.Headers["X-Forwarded-For"];
            string responseMessage = string.IsNullOrEmpty(name)
                ? "BackEndAPI executed successfully. no name"
                : $"BackEndAPI: Hello, {name} thank you for calling Me:BackEndAPI. \nYou called me from:{clientIP}. \nHave a great day!";

            return new OkObjectResult(responseMessage);
        }

    }
}
