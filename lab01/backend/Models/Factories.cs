using System;

namespace SmartHomeAPI.Models
{
    // =================================================================
    // ABSTRACT FACTORY
    // =================================================================
    public interface ISmartHomeFactory
    {
        ILamp CreateLamp();
        ISocket CreateSocket();
        IVacuumCleaner CreateVacuum();
        ISensor CreateSensor();
        string GetFactoryName();
    }

    // =================================================================
    // CONCRETE FACTORIES
    // =================================================================
    public class XiaomiFactory : ISmartHomeFactory
    {
        public ILamp CreateLamp() => new XiaomiLamp();
        public ISocket CreateSocket() => new XiaomiSocket();
        public IVacuumCleaner CreateVacuum() => new XiaomiVacuum();
        public ISensor CreateSensor() => new XiaomiSensor();
        public string GetFactoryName() => "Xiaomi";
    }

    public class ZigbeeFactory : ISmartHomeFactory
    {
        public ILamp CreateLamp() => new ZigbeeLamp();
        public ISocket CreateSocket() => new ZigbeeSocket();
        public IVacuumCleaner CreateVacuum() => new ZigbeeVacuum();
        public ISensor CreateSensor() => new ZigbeeSensor();
        public string GetFactoryName() => "Zigbee";
    }

    public class TuyaFactory : ISmartHomeFactory
    {
        public ILamp CreateLamp() => new TuyaLamp();
        public ISocket CreateSocket() => new TuyaSocket();
        public IVacuumCleaner CreateVacuum() => new TuyaVacuum();
        public ISensor CreateSensor() => new TuyaSensor();
        public string GetFactoryName() => "Tuya";
    }
}
