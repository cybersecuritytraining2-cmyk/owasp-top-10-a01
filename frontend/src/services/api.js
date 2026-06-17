import axios from "axios";

const http = axios.create({ baseURL: "/api" });

// Attach the bearer token (saved at login) to every request.
http.interceptors.request.use((config) => {
  const token = localStorage.getItem("vs_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Auth ──────────────────────────────────────────────────────────────────────
export const login = (username, password) =>
  http.post("/login", { username, password });

export const logout = () => http.post("/logout");

// ── Customer ──────────────────────────────────────────────────────────────────
export const getMe = () => http.get("/me");

export const getTransactions = (accountNumber) =>
  http.get(`/accounts/${accountNumber}/transactions`);

export const openAccount = (label) => http.post("/accounts", { label });

// ── Statement export ────────────────────────────────────────────────────────────
export const exportStatement = (accountNumber) =>
  http.post("/exports", { account_number: accountNumber });

export const downloadExport = (path) =>
  http.get(`/exports/${path}`, { responseType: "blob" });

export const transfer = (toAccount, amount) =>
  http.post("/transfers", { to_account: toAccount, amount });

export const payCard = (fromAccount, amount) =>
  http.post("/cards/pay", { from_account: fromAccount, amount });

// ── Operations console ──────────────────────────────────────────────────────────
// Endpoints behind the /admin operations console.
export const adminLogs = () => http.get("/admin/logs");
export const adminTransactions = () => http.get("/admin/transactions");
export const adminUsers = () => http.get("/admin/users");
export const adminBlock = (id) => http.post(`/admin/users/${id}/block`);
export const adminUnblock = (id) => http.post(`/admin/users/${id}/unblock`);
