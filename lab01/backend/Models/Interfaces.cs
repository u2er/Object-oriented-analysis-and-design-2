using System;

namespace SmartHomeAPI.Models
{
    // =================================================================
    // ABSTRACT PRODUCTS (Device Interfaces)
    // =================================================================
    public interface IDevice
    {
        Guid Id { get; }
        string Type { get; }
        string Brand { get; }
        bool IsOn { get; }
        void Tick();
    }

    public interface ILamp : IDevice
    {
        void TurnOn();
        void TurnOff();
        void SetColor(string color);
        string GetColor();
    }

    public interface ISocket : IDevice
    {
        void TurnOn();
        void TurnOff();
        double GetPowerConsumption();
    }

    public interface IVacuumCleaner : IDevice
    {
        void StartCleaning();
        void ReturnToDock();
        string GetStatus();
        int BatteryLevel { get; }
    }

    public interface ISensor : IDevice
    {
        double GetTemperature();
        double GetHumidity();
    }
}
