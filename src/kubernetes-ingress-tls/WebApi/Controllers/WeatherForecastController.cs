using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger)
        {
            _logger = logger;
        }

        [HttpGet(Name = "WeatherForecasts")]
        public IEnumerable<WeatherForecast> Get()
        {
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }

        [HttpGet("{id}", Name = "WeatherForecastById")]
        public WeatherForecast Get(int id)
        {
#pragma warning disable CS8603 // Possible null reference return.
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Id = index,
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            }).FirstOrDefault(w => w.Id == id);
#pragma warning restore CS8603 // Possible null reference return.
        }

        [HttpPost(Name = "CreateWeatherForecast")]
        public IActionResult Post([FromBody] WeatherForecast WeatherForecast)
        {
            return CreatedAtRoute("WeatherForecastById", new { id = WeatherForecast.Id }, WeatherForecast);
        }

        [HttpPut(Name = "UpdateWeatherForecast")]
        public IActionResult Put([FromBody] WeatherForecast WeatherForecast)
        {
            return CreatedAtRoute("WeatherForecastById", new { id = WeatherForecast.Id }, WeatherForecast);
        }

        [HttpDelete("{id}", Name = "DeleteWeatherForecast")]
        public IActionResult Delete(int id)
        {
            return NoContent();
        }
    }
}