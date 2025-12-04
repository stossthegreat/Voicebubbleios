console.log("SERVER STARTING… LOADING FILES NOW");
process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT EXCEPTION:", err);
});
process.on("unhandledRejection", (reason) => {
  console.error("UNHANDLED REJECTION:", reason);
});
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import { initRedis, closeRedis, redisHealthCheck } from './config/redis.js';
import { getCacheStats } from './utils/cache.js';
import { checkOpenAIHealth } from './utils/openai.js';

import transcribeRouter from './routes/transcribe.js';
import rewriteRouter from './routes/rewrite.js';
import subscriptionRouter from './routes/subscription.js';

// Load env
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// ===== MIDDLEWARE =====

// Security headers
app.use(
  helmet({
    contentSecurityPolicy: false, // allow SSE
    crossOriginEmbedderPolicy: false,
  })
);

// CORS
app.use(
  cors({
    origin:
      NODE_ENV === 'production'
        ? [
            'https://voicebubble.app',
            'https://www.voicebubble.app',
            /\.railway\.app$/,
          ]
        : '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  })
);

// Compression
app.use(
  compression({
    filter: (req, res) => {
      if (req.headers['x-no-compression']) return false;
      return compression.filter(req, res);
    },
    level: 6,
  })
);

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting (only /api)
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
  message: {
    error: 'Too many requests',
    message: 'Please try again later',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.path === '/health',
});

app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// ===== ROUTES =====

// 🚑 HEALTH CHECK – ALWAYS 200 (Railway-safe)
app.get('/health', async (req, res) => {
  const timestamp = new Date().toISOString();

  // Everything in here is *best-effort* – nothing is allowed to crash or 503.
  let redisStatus;
  let openaiStatus;

  try {
    redisStatus = await redisHealthCheck();
  } catch (err) {
    console.error('Redis health error:', err.message);
    redisStatus = { status: 'error', message: err.message };
  }

  try {
    const ok = await checkOpenAIHealth();
    openaiStatus = {
      status: ok ? 'healthy' : 'unhealthy',
      configured: !!process.env.OPENAI_API_KEY,
    };
  } catch (err) {
    console.error('OpenAI health error:', err.message);
    openaiStatus = {
      status: 'error',
      configured: !!process.env.OPENAI_API_KEY,
      message: err.message,
    };
  }

  // NEVER return 503 here – we only *report* diagnostics.
  res.status(200).json({
    status: 'ok',
    environment: NODE_ENV,
    timestamp,
    services: {
      redis: redisStatus,
      openai: openaiStatus,
    },
  });
});

// 📊 STATS
app.get('/stats', async (req, res) => {
  try {
    const cacheStats = await getCacheStats();

    res.json({
      uptime_seconds: process.uptime(),
      memory_usage: process.memoryUsage(),
      node_version: process.version,
      cache: cacheStats,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Stats error:', error);
    res.status(500).json({
      error: 'Failed to get stats',
      message: error.message,
    });
  }
});

// API routes
app.use('/api/transcribe', transcribeRouter);
app.use('/api/rewrite', rewriteRouter);
app.use('/api/subscription', subscriptionRouter);

// Root
app.get('/', (req, res) => {
  res.json({
    name: 'VoiceBubble API',
    version: '1.0.0',
    description: 'High-performance backend for voice transcription and text rewriting',
    endpoints: {
      health: '/health',
      stats: '/stats',
      transcribe: 'POST /api/transcribe',
      rewrite: 'POST /api/rewrite (SSE streaming)',
      rewrite_batch: 'POST /api/rewrite/batch',
    },
    documentation: 'https://github.com/yourusername/voicebubble',
  });
});

// 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Route ${req.method} ${req.path} not found`,
    available_endpoints: ['/', '/health', '/stats', '/api/transcribe', '/api/rewrite'],
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: err.name || 'Internal server error',
    message: err.message || 'An unexpected error occurred',
    ...(NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// ===== SERVER INITIALISATION =====

let server;

async function startServer() {
  try {
    console.log('Starting VoiceBubble backend…');

    // Init Redis (non-fatal)
    try {
      await initRedis();
    } catch (err) {
      console.error('Redis init failed (continuing without cache):', err.message);
    }

    if (!process.env.OPENAI_API_KEY) {
      console.warn('WARNING: OPENAI_API_KEY not set. OpenAI calls will fail.');
    } else {
      console.log('OpenAI API key detected.');
    }

    server = app.listen(PORT, '0.0.0.0', () => {
      console.log('');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('🚀 VoiceBubble Backend Server Running');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`📍 Environment: ${NODE_ENV}`);
      console.log(`🌐 Port: ${PORT}`);
      console.log(`💚 Health: http://localhost:${PORT}/health`);
      console.log(`📊 Stats: http://localhost:${PORT}/stats`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('');
    });

    server.keepAliveTimeout = 65000;
    server.headersTimeout = 66000;
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
async function gracefulShutdown(signal) {
  console.log(`\n${signal} received. Starting graceful shutdown...`);

  if (server) {
    await new Promise((resolve) => {
      server.close(() => {
        console.log('HTTP server closed');
        resolve();
      });
    });
  }

  try {
    await closeRedis();
  } catch (err) {
    console.error('Error closing Redis connection:', err.message);
  }

  console.log('Shutdown complete');
  process.exit(0);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  gracefulShutdown('uncaughtException');
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start
startServer();

export default app;
