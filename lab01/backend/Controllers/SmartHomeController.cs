using Microsoft.AspNetCore.Mvc;
using SmartHomeAPI.Services;
using SmartHomeAPI.Models;
using System;
using System.Linq;

namespace SmartHomeAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SmartHomeController : ControllerBase
    {
        private readonly SmartHomeManagerNoPattern _manager;

        public SmartHomeController(SmartHomeManagerNoPattern manager)
        {
            _manager = manager;
        }

        [HttpGet("factory")]
        public IActionResult GetCurrentFactory()
        {
            return Ok(new { factory = _manager.GetFactoryName() });
        }

        [HttpPost("factory")]
        public IActionResult SetFactory([FromBody] string factoryType)
        {
            try
            {
                _manager.SetFactory(factoryType);
                return Ok(new { factory = _manager.GetFactoryName() });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("devices")]
        public IActionResult GetDevices()
        {
            var devices = _manager.GetCurrentEcosystemDevices().Select(d => new
            {
                d.Id,
                d.Type,
                d.Brand,
                d.IsOn,
                Details = GetDeviceDetails(d)
            });
            return Ok(devices);
        }

        private object GetDeviceDetails(IDevice device)
        {
            if (device is ILamp l) return new { Color = l.GetColor() };
            if (device is ISocket s) return new { Power = s.GetPowerConsumption() };
            if (device is IVacuumCleaner v) return new { Status = v.GetStatus(), Battery = v.BatteryLevel };
            if (device is ISensor sn) return new { Temp = sn.GetTemperature(), Humidity = sn.GetHumidity() };
            return null;
        }

        [HttpPost("devices")]
        public IActionResult AddDevice([FromBody] string type)
        {
            try
            {
                var device = _manager.AddDevice(type);
                return Ok(new { device.Id, device.Type, device.Brand, device.IsOn, Details = GetDeviceDetails(device) });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpDelete("devices/{id}")]
        public IActionResult RemoveDevice(Guid id)
        {
            _manager.RemoveDevice(id);
            return NoContent();
        }

        [HttpPost("devices/{id}/toggle")]
        public IActionResult ToggleDevice(Guid id)
        {
            var device = _manager.GetDevice(id);
            if (device == null) return NotFound();

            if (device is ILamp l)
            {
                if (l.IsOn) l.TurnOff(); else l.TurnOn();
            }
            else if (device is ISocket s)
            {
                if (s.IsOn) s.TurnOff(); else s.TurnOn();
            }
            else if (device is IVacuumCleaner v)
            {
                if (v.IsOn) v.ReturnToDock(); else v.StartCleaning();
            }
            else if (device is ISensor) {}

            return Ok(new { device.IsOn, Details = GetDeviceDetails(device) });
        }

        [HttpPost("devices/{id}/color")]
        public IActionResult SetColor(Guid id, [FromBody] string color)
        {
            var device = _manager.GetDevice(id);
            if (device is ILamp l)
            {
                l.SetColor(color);
                return Ok(new { Color = l.GetColor() });
            }
            return BadRequest("Device is not a lamp");
        }
    }
}
