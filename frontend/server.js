const path = require("path");
const express = require("express");
const { createProxyMiddleware } = require('http-proxy-middleware');

require("dotenv").config({ path: path.join(__dirname, ".env") });

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:5000";

// Forward all /api requests internally to the backend container
app.use('/api', createProxyMiddleware({ 
  target: BACKEND_URL, 
  changeOrigin: true 
}));

app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "frontend", backend_url: BACKEND_URL });
});

// Tell the browser to use relative paths for the backend
app.get("/config", (_req, res) => {
  res.json({ backendUrl: "" }); 
});

app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Frontend running at http://localhost:${PORT}`);
  console.log(`Backend API target: ${BACKEND_URL}`);
});
