const path = require("path");
const express = require("express");

require("dotenv").config({ path: path.join(__dirname, ".env") });

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:5000";

app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "frontend", backend_url: BACKEND_URL });
});

app.get("/config", (_req, res) => {
  res.json({ backendUrl: BACKEND_URL });
});

app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Frontend running at http://localhost:${PORT}`);
  console.log(`Backend API target: ${BACKEND_URL}`);
});
