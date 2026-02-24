// import React from "react";
import { Lightbulb, Power, BatteryCharging, Thermometer, Trash2 } from "lucide-react";

interface DeviceCardProps {
  device: any;
  onToggle: (id: string) => void;
  onDelete: (id: string) => void;
  onColorChange: (id: string, color: string) => void;
}

export const DeviceCard: React.FC<DeviceCardProps> = ({ device, onToggle, onDelete, onColorChange }) => {
  const getIcon = () => {
    switch (device.type) {
      case "Lamp": return <Lightbulb className={device.isOn ? "text-yellow-400" : "text-gray-400"} />;
      case "Socket": return <Power className={device.isOn ? "text-green-500" : "text-gray-400"} />;
      case "Vacuum": return <BatteryCharging className={device.isOn ? "text-blue-500" : "text-gray-400"} />;
      case "Sensor": return <Thermometer className="text-red-400" />;
      default: return <Power />;
    }
  };

  const getStatusText = () => {
    if (device.type === "Sensor") {
      return (
        <div className="text-xs text-gray-500">
          Temp: {device.details?.temp?.toFixed(1)}°C <br/>
          Humidity: {device.details?.humidity?.toFixed(1)}%
        </div>
      );
    }
    if (device.type === "Lamp") {
      return (
        <div className="flex flex-col gap-1">
           <span className="text-xs">{device.isOn ? "On" : "Off"} - {device.details?.color}</span>
           {device.isOn && (
             <div className="flex gap-1 mt-1">
               {["White", "Red", "Blue", "Green"].map(c => (
                 <button 
                   key={c}
                   onClick={(e) => { e.stopPropagation(); onColorChange(device.id, c); }}
                   className={`w-4 h-4 rounded-full border border-gray-200 ${c === "White" ? "bg-white" : c === "Red" ? "bg-red-500" : c === "Blue" ? "bg-blue-500" : "bg-green-500"}`}
                   title={c}
                 />
               ))}
             </div>
           )}
        </div>
      );
    }
    if (device.type === "Socket") {
      return <span className="text-xs">{device.isOn ? `${device.details?.power?.toFixed(1)} W` : "Off"}</span>;
    }
    if (device.type === "Vacuum") {
      const battery = device.details?.battery ?? 100;
      return (
        <div className="flex flex-col gap-1 w-full">
          <span className="text-xs">{device.details?.status || (device.isOn ? "Cleaning" : "Docked")}</span>
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <div 
              className={`h-1.5 rounded-full ${battery < 20 ? "bg-red-500" : "bg-green-500"}`} 
              style={{ width: `${battery}%` }} 
            />
          </div>
          <span className="text-[10px] text-gray-500">{battery}%</span>
        </div>
      );
    }
    return <span className="text-xs">{device.isOn ? "On" : "Off"}</span>;
  };

  return (
    <div 
      className={`
        relative p-4 rounded-xl border shadow-sm transition-all duration-200
        ${device.isOn ? "bg-white border-blue-200 shadow-blue-50" : "bg-gray-50 border-gray-200"}
        hover:shadow-md cursor-pointer
      `}
      onClick={() => device.type !== "Sensor" && onToggle(device.id)}
    >
      <div className="flex justify-between items-start mb-2">
        <div className="p-2 rounded-full bg-gray-100">
          {getIcon()}
        </div>
        <button 
          onClick={(e) => { e.stopPropagation(); onDelete(device.id); }}
          className="text-gray-400 hover:text-red-500 transition-colors p-1"
        >
          <Trash2 size={16} />
        </button>
      </div>
      
      <div>
        <h3 className="font-medium text-gray-900">{device.type}</h3>
        <p className="text-xs text-gray-500 mb-2">{device.brand}</p>
        {getStatusText()}
      </div>
    </div>
  );
};
