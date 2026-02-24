import { useEffect, useState } from "react";
import { api, Device } from "@/lib/api";
import { DeviceCard } from "@/components/DeviceCard";
import { Plus, LayoutGrid, Factory, Server } from "lucide-react";

export function App() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [factory, setFactory] = useState<string>("Xiaomi");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshData = async () => {
    try {
      const f = await api.getFactory();
      setFactory(f);
      const d = await api.getDevices();
      setDevices(d);
      setError(null);
    } catch (err: any) {
      console.error(err);
      setError("Failed to connect to backend. Please ensure the API is running.");
    } finally {
      setLoading(false);
    }
  };

      useEffect(() => {
    refreshData();
    const interval = setInterval(refreshData, 1000); // Poll every 1 second
    return () => clearInterval(interval);
  }, []);

  const handleSetFactory = async (newFactory: string) => {
    try {
      await api.setFactory(newFactory);
      setFactory(newFactory);
      refreshData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleAddDevice = async (type: string) => {
    try {
      await api.addDevice(type);
      refreshData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleRemoveDevice = async (id: string) => {
    try {
      await api.removeDevice(id);
      setDevices(prev => prev.filter(d => d.id !== id));
    } catch (err) {
      console.error(err);
    }
  };

  const handleToggleDevice = async (id: string) => {
    try {
      await api.toggleDevice(id);
      refreshData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleColorChange = async (id: string, color: string) => {
    try {
      await api.setColor(id, color);
      refreshData();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 font-sans">
      {/* Header */}
      <header className="bg-white border-b sticky top-0 z-10 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="bg-indigo-600 p-2 rounded-lg text-white">
              <LayoutGrid size={24} />
            </div>
            <h1 className="text-xl font-bold tracking-tight text-gray-900">Smart Home Manager</h1>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-sm text-gray-500 bg-gray-100 px-3 py-1.5 rounded-full">
              <Server size={14} />
              <span>System: <strong className="text-gray-900">{factory}</strong></span>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative" role="alert">
            <strong className="font-bold">Error: </strong>
            <span className="block sm:inline">{error}</span>
          </div>
        )}

        {/* Factory Selection */}
        <section className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Factory size={20} className="text-gray-500" />
            Select Ecosystem
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {["Xiaomi", "Zigbee", "Tuya"].map((f) => (
              <button
                key={f}
                onClick={() => handleSetFactory(f)}
                className={`
                  relative flex flex-col items-center justify-center p-6 rounded-xl border-2 transition-all
                  ${factory === f 
                    ? "border-indigo-600 bg-indigo-50 text-indigo-700" 
                    : "border-gray-200 bg-white hover:border-indigo-200 hover:bg-gray-50 text-gray-600"}
                `}
              >
                <span className="text-lg font-medium">{f}</span>
                <span className="text-xs mt-1 opacity-75">
                  {f === "Xiaomi" ? "Wi-Fi / Cloud" : f === "Zigbee" ? "Local Gateway" : "Smart Life Cloud"}
                </span>
              </button>
            ))}
          </div>
        </section>

        {/* Device Management */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Devices</h2>
            <div className="flex gap-2">
              {["Lamp", "Socket", "Vacuum", "Sensor"].map((type) => (
                <button
                  key={type}
                  onClick={() => handleAddDevice(type)}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors shadow-sm"
                >
                  <Plus size={16} />
                  Add {type}
                </button>
              ))}
            </div>
          </div>

          {loading && devices.length === 0 ? (
            <div className="text-center py-12 text-gray-500">Loading devices...</div>
          ) : devices.length === 0 ? (
            <div className="text-center py-12 border-2 border-dashed border-gray-200 rounded-xl bg-gray-50">
              <p className="text-gray-500">No devices added yet.</p>
              <p className="text-sm text-gray-400 mt-1">Select a device type above to add one.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {devices.map((device) => (
                <DeviceCard
                  key={device.id}
                  device={device}
                  onToggle={() => handleToggleDevice(device.id)}
                  onDelete={() => handleRemoveDevice(device.id)}
                  onColorChange={handleColorChange}
                />
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
