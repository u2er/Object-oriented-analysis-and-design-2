import axios from "axios";

// Toggle this to false if running with the real C# backend
const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true' || true; // Default to true for demo, can be overridden

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8080/api/SmartHome";

export interface Device {
  id: string;
  type: string;
  brand: string;
  isOn: boolean;
  details?: any;
}

export interface SmartHomeAPI {
  getFactory: () => Promise<string>;
  setFactory: (factory: string) => Promise<string>;
  getDevices: () => Promise<Device[]>;
  addDevice: (type: string) => Promise<Device>;
  removeDevice: (id: string) => Promise<void>;
  toggleDevice: (id: string) => Promise<Device>;
  setColor: (id: string, color: string) => Promise<string>;
}

// --- MOCK IMPLEMENTATION ---
let mockFactory = "Xiaomi";
let mockDevices: Device[] = [];

const mockApi: SmartHomeAPI = {
  getFactory: async () => mockFactory,
  setFactory: async (factory) => {
    mockFactory = factory;
    return mockFactory;
  },
  getDevices: async () => {
    // Simulate dynamic changes
    mockDevices.forEach(d => {
      if (d.type === "Socket" && d.isOn) {
        d.details = { power: 100 + Math.random() * 50 };
      }
      if (d.type === "Sensor") {
        d.details = { 
          temp: 20 + Math.random() * 5, 
          humidity: 40 + Math.random() * 10 
        };
      }
      if (d.type === "Vacuum") {
        let battery = d.details.battery || 100;
        if (d.isOn) {
          battery = Math.max(0, battery - 5);
          if (battery <= 10) { d.isOn = false; d.details.status = "Docked"; }
          else d.details.status = "Cleaning";
        } else {
          battery = Math.min(100, battery + 5);
          d.details.status = "Docked";
        }
        d.details.battery = battery;
      }
    });
    return mockDevices.filter(d => d.brand === mockFactory);
  },
  addDevice: async (type) => {
    const id = Math.random().toString(36).substr(2, 9);
    const newDevice: Device = {
      id,
      type,
      brand: mockFactory,
      isOn: false,
      details: type === "Lamp" ? { color: "White" } : 
               type === "Socket" ? { power: 0 } :
               type === "Vacuum" ? { status: "Docked", battery: 100 } :
               { temp: 20 + Math.random() * 5, humidity: 40 + Math.random() * 10 }
    };
    mockDevices.push(newDevice);
    return newDevice;
  },
  removeDevice: async (id) => {
    mockDevices = mockDevices.filter(d => d.id !== id);
  },
  toggleDevice: async (id) => {
    const device = mockDevices.find(d => d.id === id);
    if (device) {
      device.isOn = !device.isOn;
      // Update mock details based on state
      if (device.type === "Socket") {
         device.details = { ...device.details, power: device.isOn ? 100 + Math.random() * 50 : 0 };
      }
      if (device.type === "Vacuum") {
         device.details = { ...device.details, status: device.isOn ? "Cleaning" : "Docked" };
      }
      return { ...device };
    }
    throw new Error("Device not found");
  },
  setColor: async (id, color) => {
    const device = mockDevices.find(d => d.id === id);
    if (device && device.type === "Lamp") {
      device.details = { ...device.details, color };
      return color;
    }
    throw new Error("Device not found or not a lamp");
  }
};

// --- REAL IMPLEMENTATION ---
const realApi: SmartHomeAPI = {
  getFactory: async () => (await axios.get(`${API_URL}/factory`)).data.factory,
  setFactory: async (factory) => (await axios.post(`${API_URL}/factory`, JSON.stringify(factory), { headers: { 'Content-Type': 'application/json' } })).data.factory,
  getDevices: async () => (await axios.get(`${API_URL}/devices`)).data,
  addDevice: async (type) => (await axios.post(`${API_URL}/devices`, JSON.stringify(type), { headers: { 'Content-Type': 'application/json' } })).data,
  removeDevice: async (id) => await axios.delete(`${API_URL}/devices/${id}`),
  toggleDevice: async (id) => (await axios.post(`${API_URL}/devices/${id}/toggle`)).data,
  setColor: async (id, color) => (await axios.post(`${API_URL}/devices/${id}/color`, JSON.stringify(color), { headers: { 'Content-Type': 'application/json' } })).data.color
};

export const api = USE_MOCK ? mockApi : realApi;
