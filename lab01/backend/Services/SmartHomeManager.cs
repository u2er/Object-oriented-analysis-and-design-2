using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using SmartHomeAPI.Models;

namespace SmartHomeAPI.Services
{
    public class SmartHomeManager : IDisposable
    {
        private ISmartHomeFactory _currentFactory;
        private readonly List<IDevice> _devices = new List<IDevice>();
        private readonly Timer _timer;
        private readonly object _lock = new object();

        public SmartHomeManager()
        {
            _currentFactory = new XiaomiFactory();
            _timer = new Timer(OnTick, null, 1000, 1000);
        }

        private void OnTick(object state)
        {
            lock (_lock)
            {
                foreach (var device in _devices)
                {
                    device.Tick();
                }
            }
        }

        public void SetFactory(string type)
        {
            switch (type.ToLower())
            {
                case "xiaomi": _currentFactory = new XiaomiFactory(); break;
                case "zigbee": _currentFactory = new ZigbeeFactory(); break;
                case "tuya": _currentFactory = new TuyaFactory(); break;
                default: throw new ArgumentException("Unknown factory type");
            }
        }

        public string GetFactoryName() => _currentFactory.GetFactoryName();

        public IDevice AddDevice(string type)
        {
            IDevice device = type.ToLower() switch
            {
                "lamp" => _currentFactory.CreateLamp(),
                "socket" => _currentFactory.CreateSocket(),
                "vacuum" => _currentFactory.CreateVacuum(),
                "sensor" => _currentFactory.CreateSensor(),
                _ => throw new ArgumentException("Unknown device type")
            };
            lock (_lock)
            {
                _devices.Add(device);
            }
            return device;
        }

        public void RemoveDevice(Guid id)
        {
            lock (_lock)
            {
                var device = _devices.FirstOrDefault(d => d.Id == id);
                if (device != null) _devices.Remove(device);
            }
        }

        public IEnumerable<IDevice> GetAllDevices()
        {
            lock (_lock)
            {
                return new List<IDevice>(_devices);
            }
        }
        
        public IEnumerable<IDevice> GetCurrentEcosystemDevices()
        {
            lock (_lock)
            {
                string currentBrand = _currentFactory.GetFactoryName();
                return _devices.Where(d => d.Brand.Equals(currentBrand, StringComparison.OrdinalIgnoreCase)).ToList();
            }
        }

        public IDevice GetDevice(Guid id)
        {
            lock (_lock)
            {
                return _devices.FirstOrDefault(d => d.Id == id);
            }
        }

        public void ToggleDevice(Guid id)
        {
            var device = GetDevice(id);
            if (device == null) return;
        }

        public void Dispose()
        {
            _timer?.Dispose();
        }
    }


    // =================================================================
    // ВАРИАНТ БЕЗ ПАТТЕРНА
    // =================================================================

    public class SmartHomeManagerNoPattern : IDisposable
    {
        private string _currentBrand; 
        
        private readonly List<IDevice> _devices = new List<IDevice>();
        private readonly Timer _timer;
        private readonly object _lock = new object();

        public SmartHomeManagerNoPattern()
        {
            _currentBrand = "Xiaomi";
            _timer = new Timer(OnTick, null, 1000, 1000);
        }

        private void OnTick(object state)
        {
            lock (_lock)
            {
                foreach (var device in _devices)
                {
                    device.Tick();
                }
            }
        }

        public void SetFactory(string type)
        {
            string requestedBrand = type.ToLower() switch
            {
                "xiaomi" => "Xiaomi",
                "zigbee" => "Zigbee",
                "tuya" => "Tuya",
                _ => throw new ArgumentException("Unknown brand type")
            };
            
            _currentBrand = requestedBrand;
        }

        public string GetFactoryName() => _currentBrand;

        public IDevice AddDevice(string type)
        {
            IDevice device = (_currentBrand.ToLower(), type.ToLower()) switch
            {
                // Xiaomi
                ("xiaomi", "lamp") => new XiaomiLamp(),
                ("xiaomi", "socket") => new XiaomiSocket(),
                ("xiaomi", "vacuum") => new XiaomiVacuum(),
                ("xiaomi", "sensor") => new XiaomiSensor(),

                // Zigbee
                ("zigbee", "lamp") => new ZigbeeLamp(),
                ("zigbee", "socket") => new ZigbeeSocket(),
                ("zigbee", "vacuum") => new ZigbeeVacuum(),
                ("zigbee", "sensor") => new ZigbeeSensor(),

                // Tuya
                ("tuya", "lamp") => new TuyaLamp(),
                ("tuya", "socket") => new TuyaSocket(),
                ("tuya", "vacuum") => new TuyaVacuum(),
                ("tuya", "sensor") => new TuyaSensor(),

                _ => throw new ArgumentException($"Unknown device type '{type}' for brand '{_currentBrand}'")
            };

            lock (_lock)
            {
                _devices.Add(device);
            }
            
            return device;
        }

        public void RemoveDevice(Guid id)
        {
            lock (_lock)
            {
                var device = _devices.FirstOrDefault(d => d.Id == id);
                if (device != null) _devices.Remove(device);
            }
        }

        public IEnumerable<IDevice> GetAllDevices()
        {
            lock (_lock)
            {
                return new List<IDevice>(_devices);
            }
        }
        
        public IEnumerable<IDevice> GetCurrentEcosystemDevices()
        {
            lock (_lock)
            {
                return _devices.Where(d => d.Brand.Equals(_currentBrand, StringComparison.OrdinalIgnoreCase)).ToList();
            }
        }

        public IDevice GetDevice(Guid id)
        {
            lock (_lock)
            {
                return _devices.FirstOrDefault(d => d.Id == id);
            }
        }

        public void ToggleDevice(Guid id)
        {
            var device = GetDevice(id);
            if (device == null) return;
        }

        public void Dispose()
        {
            _timer?.Dispose();
        }
    }
}
