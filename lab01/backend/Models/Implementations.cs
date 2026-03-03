using System;

namespace SmartHomeAPI.Models
{
    // =================================================================
    // CONCRETE PRODUCTS (Implementations for different brands)
    // =================================================================

    public abstract class BaseDevice : IDevice
    {
        public Guid Id { get; } = Guid.NewGuid();
        public abstract string Brand { get; }
        public abstract string Type { get; }
        public bool IsOn { get; protected set; } = false;

        protected static readonly Random _random = new Random();

        public virtual void Tick() { }
    }

    // --- XIAOMI ---
    public class XiaomiLamp : BaseDevice, ILamp
    {
        public override string Brand => "Xiaomi";
        public override string Type => "Lamp";
        private string _color = "White";

        public void TurnOn() { IsOn = true; }
        public void TurnOff() { IsOn = false; }
        public void SetColor(string color) { _color = color; }
        public string GetColor() => _color;
    }

    public class XiaomiSocket : BaseDevice, ISocket
    {
        public override string Brand => "Xiaomi";
        public override string Type => "Socket";
        private double _power = 0;

        public void TurnOn() { IsOn = true; _power = 120.0; }
        public void TurnOff() { IsOn = false; _power = 0; }
        public double GetPowerConsumption() => _power;

        public override void Tick()
        {
            if (IsOn)
            {
                _power = 120.0 + (_random.NextDouble() * 10 - 5);
            }
            else
            {
                _power = 0;
            }
        }
    }

    public class XiaomiVacuum : BaseDevice, IVacuumCleaner
    {
        public override string Brand => "Xiaomi";
        public override string Type => "Vacuum";
        private string _status = "Docked";
        public int BatteryLevel { get; private set; } = 100;

        public void StartCleaning() 
        { 
            if (BatteryLevel > 10)
            {
                IsOn = true; 
                _status = "Cleaning (Lidar)"; 
            }
        }
        public void ReturnToDock() 
        { 
            IsOn = false; 
            _status = "Returning to Dock"; 
        }
        public string GetStatus() => _status;

        public override void Tick()
        {
            if (IsOn)
            {
                BatteryLevel = Math.Max(0, BatteryLevel - 2);
                if (BatteryLevel <= 10)
                {
                    ReturnToDock();
                }
            }
            else
            {
                if (BatteryLevel < 100)
                {
                    BatteryLevel = Math.Min(100, BatteryLevel + 5);
                    _status = "Charging";
                }
                else
                {
                    _status = "Docked";
                }
            }
        }
    }

    public class XiaomiSensor : BaseDevice, ISensor
    {
        public override string Brand => "Xiaomi";
        public override string Type => "Sensor";
        private double _temp = 24.5;
        private double _humidity = 45.0;

        public double GetTemperature() => _temp;
        public double GetHumidity() => _humidity;

        public override void Tick()
        {
            _temp = 24.5 + (_random.NextDouble() * 2 - 1);
            _humidity = 45.0 + (_random.NextDouble() * 4 - 2);
        }
    }

    // --- ZIGBEE ---
    public class ZigbeeLamp : BaseDevice, ILamp
    {
        public override string Brand => "Zigbee";
        public override string Type => "Lamp";
        private string _color = "White";

        public void TurnOn() { IsOn = true; }
        public void TurnOff() { IsOn = false; }
        public void SetColor(string color) { _color = color; }
        public string GetColor() => _color;
    }

    public class ZigbeeSocket : BaseDevice, ISocket
    {
        public override string Brand => "Zigbee";
        public override string Type => "Socket";
        private double _power = 0;

        public void TurnOn() { IsOn = true; _power = 118.0; }
        public void TurnOff() { IsOn = false; _power = 0.1; }
        public double GetPowerConsumption() => _power;

        public override void Tick()
        {
            if (IsOn)
                _power = 118.0 + (_random.NextDouble() * 4 - 2);
            else
                _power = 0.1;
        }
    }

    public class ZigbeeVacuum : BaseDevice, IVacuumCleaner
    {
        public override string Brand => "Zigbee";
        public override string Type => "Vacuum";
        private string _status = "Docked";
        public int BatteryLevel { get; private set; } = 100;

        public void StartCleaning() 
        { 
            if (BatteryLevel > 10)
            {
                IsOn = true; 
                _status = "Mapping & Cleaning"; 
            }
        }
        public void ReturnToDock() 
        { 
            IsOn = false; 
            _status = "Charging"; 
        }
        public string GetStatus() => _status;

        public override void Tick()
        {
            if (IsOn)
            {
                BatteryLevel = Math.Max(0, BatteryLevel - 3);
                if (BatteryLevel <= 10) ReturnToDock();
            }
            else
            {
                if (BatteryLevel < 100)
                {
                    BatteryLevel = Math.Min(100, BatteryLevel + 4);
                    _status = "Charging";
                }
                else _status = "Docked";
            }
        }
    }

    public class ZigbeeSensor : BaseDevice, ISensor
    {
        public override string Brand => "Zigbee";
        public override string Type => "Sensor";
        private double _temp = 23.8;
        private double _humidity = 42.5;

        public double GetTemperature() => _temp;
        public double GetHumidity() => _humidity;

        public override void Tick()
        {
            _temp = 23.8 + (_random.NextDouble() * 1.5 - 0.75);
            _humidity = 42.5 + (_random.NextDouble() * 3 - 1.5);
        }
    }

    // --- TUYA ---
    public class TuyaLamp : BaseDevice, ILamp
    {
        public override string Brand => "Tuya";
        public override string Type => "Lamp";
        private string _color = "White";

        public void TurnOn() { IsOn = true; }
        public void TurnOff() { IsOn = false; }
        public void SetColor(string color) { _color = color; }
        public string GetColor() => _color;
    }

    public class TuyaSocket : BaseDevice, ISocket
    {
        public override string Brand => "Tuya";
        public override string Type => "Socket";
        private double _power = 0;

        public void TurnOn() { IsOn = true; _power = 90.0; }
        public void TurnOff() { IsOn = false; _power = 0; }
        public double GetPowerConsumption() => _power;

        public override void Tick()
        {
            if (IsOn) _power = 90.0 + (_random.NextDouble() * 8 - 4);
            else _power = 0;
        }
    }

    public class TuyaVacuum : BaseDevice, IVacuumCleaner
    {
        public override string Brand => "Tuya";
        public override string Type => "Vacuum";
        private string _status = "Docked";
        public int BatteryLevel { get; private set; } = 100;

        public void StartCleaning() 
        { 
            if (BatteryLevel > 10)
            {
                IsOn = true; 
                _status = "Chaotic Cleaning"; 
            }
        }
        public void ReturnToDock() 
        { 
            IsOn = false; 
            _status = "Searching for Base"; 
        }
        public string GetStatus() => _status;

        public override void Tick()
        {
            if (IsOn)
            {
                BatteryLevel = Math.Max(0, BatteryLevel - 4);
                if (BatteryLevel <= 10) ReturnToDock();
            }
            else
            {
                if (BatteryLevel < 100)
                {
                    BatteryLevel = Math.Min(100, BatteryLevel + 3);
                    _status = "Charging";
                }
                else _status = "Docked";
            }
        }
    }

    public class TuyaSensor : BaseDevice, ISensor
    {
        public override string Brand => "Tuya";
        public override string Type => "Sensor";
        private double _temp = 22.0;
        private double _humidity = 50.0;

        public double GetTemperature() => _temp;
        public double GetHumidity() => _humidity;

        public override void Tick()
        {
            _temp = 22.0 + (_random.NextDouble() * 3 - 1.5);
            _humidity = 50.0 + (_random.NextDouble() * 5 - 2.5);
        }
    }
}
