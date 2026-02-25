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

const realApi: SmartHomeAPI = {
  getFactory: async () => (await axios.get(`${API_URL}/factory`)).data.factory,
  setFactory: async (factory) => (await axios.post(`${API_URL}/factory`, JSON.stringify(factory), { headers: { 'Content-Type': 'application/json' } })).data.factory,
  getDevices: async () => (await axios.get(`${API_URL}/devices`)).data,
  addDevice: async (type) => (await axios.post(`${API_URL}/devices`, JSON.stringify(type), { headers: { 'Content-Type': 'application/json' } })).data,
  removeDevice: async (id) => await axios.delete(`${API_URL}/devices/${id}`),
  toggleDevice: async (id) => (await axios.post(`${API_URL}/devices/${id}/toggle`)).data,
  setColor: async (id, color) => (await axios.post(`${API_URL}/devices/${id}/color`, JSON.stringify(color), { headers: { 'Content-Type': 'application/json' } })).data.color
};

export const api = realApi;
