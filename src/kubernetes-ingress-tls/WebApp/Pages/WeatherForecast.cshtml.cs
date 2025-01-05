using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace WebApp.Pages
{
    public class WeatherForecastModel : PageModel
    {
        public string WeatherApiUrl { get; set; }
        public WeatherForecastModel(IConfiguration configuration)
        {
            // Retrieve the API URL from the environment variable or app settings
            WeatherApiUrl = configuration["WebApiUrl"] ?? throw new ArgumentNullException("WebApiUrl is not set in the configuration file");
        }
        public void OnGet()
        {
        }
    }
}
