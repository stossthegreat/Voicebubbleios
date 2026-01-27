// backend/app.js

import express from "express";
import cors from "cors";
import compression from "compression";
import helmet from "helmet";
import rateLimit from "express-rate-limit";

import rewriteRoutes from "./routes/rewrite.js";
import transcribeRoutes from "./routes/transcribe.js";
import subscriptionRoutes from "./routes/subscription.js";

import { AppError, globalErrorHandler } from "./utils/errors.js";

const app = express();

// ========= MIDDLEWARE =========

// Security headers
app.use(helmet());

// CORS
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST"],
  })
);

// Body parsing
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true, limit: "2mb" }));

// Compression = faster responses
app.use(compression());

// Basic rate limit
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1500,
    message: "Too many requests. Chill.",
  })
);

// ========= HEALTH ROUTES =========
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: Date.now() });
});

app.get("/stats", (req, res) => {
  res.json({
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    env: process.env.NODE_ENV || "development",
  });
});

// ========= APP ROUTES =========
app.use("/api/rewrite", rewriteRoutes);
app.use("/api/transcribe", transcribeRoutes);
app.use("/api/subscription", subscriptionRoutes);
app.use("/api/extract", extractRoutes);

// ========= 404 HANDLER =========
app.all("*", (req, res, next) => {
  next(new AppError(`Route not found: ${req.originalUrl}`, 404));
});

// ========= GLOBAL ERROR HANDLER =========
app.use(globalErrorHandler);

export default app;

